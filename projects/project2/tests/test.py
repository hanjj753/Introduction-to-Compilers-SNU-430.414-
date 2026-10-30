#!/usr/bin/env python3
"""Compare tests/*.c with same-named .out files after building src/subc."""
import argparse
import difflib
import itertools
import os
from pathlib import Path
import selectors
import signal
import subprocess
import time


RUN_TIMEOUT = 2
OUTPUT_LIMIT = 16 * 1024 * 1024
DIFF_BYTE_LIMIT = 16 * 1024


def run_case(project, source, actual_path, stderr_path):
    """Save bounded output and stop the entire process group on every exit path."""
    deadline = time.monotonic() + RUN_TIMEOUT
    with actual_path.open("wb") as out, stderr_path.open("wb") as err:
        with subprocess.Popen(
            [str(project / "src/subc"), str(source)], cwd=project,
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            start_new_session=True,
        ) as process:
            status = "finished"
            streams = {"stdout": out, "stderr": err}
            sizes = {name: 0 for name in streams}
            try:
                with selectors.DefaultSelector() as selector:
                    selector.register(process.stdout, selectors.EVENT_READ, "stdout")
                    selector.register(process.stderr, selectors.EVENT_READ, "stderr")
                    while selector.get_map() and status == "finished":
                        remaining = deadline - time.monotonic()
                        if remaining <= 0:
                            status = "timeout"
                            break
                        for key, _ in selector.select(timeout=remaining):
                            data = os.read(key.fd, 64 * 1024)
                            if not data:
                                selector.unregister(key.fileobj)
                                continue
                            name = key.data
                            available = OUTPUT_LIMIT - sizes[name]
                            saved = data[:available]
                            streams[name].write(saved)
                            sizes[name] += len(saved)
                            if len(data) > available:
                                status = f"{name} output limit"
                                break
                if status == "finished":
                    try:
                        process.wait(timeout=max(0, deadline - time.monotonic()))
                    except subprocess.TimeoutExpired:
                        status = "timeout"
            finally:
                # A child can retain pipes even after its parent has exited.
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait()
    return process.returncode, status


def show_difference(expected, actual, name):
    """Show invisible bytes as well as a bounded, readable line diff."""
    offset = next((i for i, (a, b) in enumerate(zip(expected, actual)) if a != b),
                  min(len(expected), len(actual)))
    print(f"  First difference at byte {offset + 1} (byte strings show whitespace):")
    start, end = max(0, offset - 20), offset + 40
    print(f"  expected: {expected[start:end]!r}")
    print(f"  actual:   {actual[start:end]!r}")
    if expected.endswith(b"\n") and actual and not actual.endswith(b"\n"):
        print("  Actual output is missing its final LF newline.")
    if b"\r\n" in actual and b"\r\n" not in expected:
        print("  Actual output contains CRLF; expected output uses LF.")
    excerpt = max(len(expected), len(actual)) > DIFF_BYTE_LIMIT
    if excerpt:
        start = max(0, offset - 256)
        end = start + DIFF_BYTE_LIMIT
        expected, actual = expected[start:end], actual[start:end]
        print("  Diff shows a bounded excerpt near the first difference; "
              "compare the saved files for the full output.")
    label = " (excerpt)" if excerpt else ""
    diff = difflib.unified_diff(
        expected.decode("utf-8", errors="backslashreplace").splitlines(keepends=True),
        actual.decode("utf-8", errors="backslashreplace").splitlines(keepends=True),
        fromfile=f"tests/{name}.out{label}", tofile=f"test-results/{name}.actual{label}",
    )
    for index, line in enumerate(itertools.islice(diff, 81)):
        if index == 80:
            print("  ... diff truncated; compare the saved files for the full output.")
            break
        text = line.rstrip("\n")
        print(text if len(text) <= 200 else text[:200] + " ... [line truncated]")
        if not line.endswith("\n"):
            print(r"\ No newline at end of excerpt" if excerpt
                  else r"\ No newline at end of file")


def check(project, case=None):
    project = Path(project).resolve()
    tests = project / "tests"
    inputs = {p.stem for p in tests.glob("*.c")}
    outputs = {p.stem for p in tests.glob("*.out")}
    names = inputs | outputs
    if case:
        if case not in names:
            print(f"FAIL: unknown test {case!r}. Use a filename stem, such as CASE=sample.")
            print("Available tests: " + (", ".join(sorted(names)) or "(none)"))
            return 1
        names = {case}
    if not names:
        print("No tests found. Add matching tests/<name>.c and tests/<name>.out files.")
        return 1
    results = project / "test-results"
    try:
        results.mkdir(exist_ok=True)
    except OSError as exc:
        print(f"FAIL: cannot create test-results/: {exc}")
        return 1
    passed = 0
    for name in sorted(names):
        actual_path = results / (name + ".actual")
        stderr_path = results / (name + ".stderr")
        try:
            # Remove only this case's generated results, including stale failures.
            actual_path.unlink(missing_ok=True)
            stderr_path.unlink(missing_ok=True)
            if name not in inputs or name not in outputs:
                print(f"FAIL {name}: provide both tests/{name}.c and tests/{name}.out")
                continue
            expected = (tests / (name + ".out")).read_bytes()
            try:
                returncode, status = run_case(
                    project, tests / (name + ".c"), actual_path, stderr_path,
                )
            except OSError as exc:
                print(f"FAIL {name}: cannot run src/subc: {exc}")
                print("  Build the completed grammar and table with make first.")
                continue
            if status != "finished":
                reason = (f"the {RUN_TIMEOUT}-second run limit (timeout)" if status == "timeout"
                          else f"the {OUTPUT_LIMIT // (1024 * 1024)}-MiB {status}")
                print(f"FAIL {name}: exceeded {reason}.")
                print(f"  Partial output: test-results/{name}.actual and {name}.stderr")
                continue
            actual = actual_path.read_bytes()
            stderr = stderr_path.read_bytes()
        except OSError as exc:
            print(f"FAIL {name}: file error: {exc}")
            continue
        problems = []
        if returncode < 0:
            problems.append(f"terminated by signal {-returncode}")
        elif returncode != 0:
            problems.append(f"nonzero exit status {returncode}")
        if stderr:
            problems.append("unexpected stderr output")
        if problems:
            print(f"FAIL {name}: " + "; ".join(problems))
            if stderr:
                print("  stderr preview: " + repr(stderr[:240]))
        elif actual != expected:
            print(f"FAIL {name}: output differs")
            show_difference(expected, actual, name)
        else:
            print(f"PASS {name}")
            passed += 1
            continue
        print(f"  Saved output: test-results/{name}.actual and {name}.stderr")
    print(f"{passed}/{len(names)} tests passed. Results: test-results/")
    return int(passed != len(names))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", default=os.environ.get("CASE") or None,
                        help="run only this filename stem (without .c or .out)")
    args = parser.parse_args()
    raise SystemExit(check(Path(__file__).resolve().parents[1], args.case))
