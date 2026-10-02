#!/usr/bin/env python3
"""Compare tests/*.c with same-named .tsv files after building src/subc."""
import difflib
from pathlib import Path
import subprocess


def check(project):
    project = Path(project).resolve()
    tests = project / "tests"
    inputs = {p.stem for p in tests.glob("*.c")}
    outputs = {p.stem for p in tests.glob("*.tsv")}
    if not inputs:
        print("No inputs found in tests/*.c.")
        return 1
    failed = False
    for name in sorted(inputs | outputs):
        if name not in inputs or name not in outputs:
            print(f"FAIL {name}: provide both {name}.c and {name}.tsv")
            failed = True
            continue
        try:
            result = subprocess.run(
                [str(project / "src/subc"), str(tests / (name + ".c"))],
                stdin=subprocess.DEVNULL, capture_output=True, timeout=2,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            print(f"FAIL {name}: {exc}")
            failed = True
            continue
        expected = (tests / (name + ".tsv")).read_bytes()
        if result.returncode != 0 or result.stderr:
            print(f"FAIL {name}: exit {result.returncode}")
            print(result.stderr.decode(errors="replace"), end="")
            failed = True
        elif result.stdout != expected:
            print(f"FAIL {name}: output differs")
            print("".join(difflib.unified_diff(
                expected.decode(errors="replace").splitlines(keepends=True),
                result.stdout.decode(errors="replace").splitlines(keepends=True),
                fromfile=name + ".tsv", tofile="actual output",
            )), end="")
            failed = True
        else:
            print(f"PASS {name}")
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(check(Path(__file__).resolve().parents[1]))
