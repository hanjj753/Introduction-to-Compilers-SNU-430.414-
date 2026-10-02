#!/usr/bin/env python3
"""Package the files selected by an assignment Makefile without changing student work."""
import argparse
import fnmatch
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import signal
import subprocess
import tempfile
import time
import zipfile

BUILD_TIMEOUT = 30
OUTPUT_LIMIT = 16 * 1024 * 1024


def run_process(command, cwd, input_bytes=b"", timeout=BUILD_TIMEOUT):
    """Bound time/output and terminate the process group, including children."""
    started = time.monotonic()
    with tempfile.TemporaryDirectory(prefix="course-process-") as work:
        paths = [Path(work) / name for name in ("stdin", "stdout", "stderr")]
        paths[0].write_bytes(input_bytes)
        with paths[0].open("rb") as inp, paths[1].open("wb") as out, paths[2].open("wb") as err:
            try:
                process = subprocess.Popen(command, cwd=cwd, stdin=inp, stdout=out,
                                           stderr=err, start_new_session=True)
            except OSError as exc:
                return {"status": "launch_error", "returncode": None,
                        "stdout": b"", "stderr": str(exc).encode(), "seconds": 0}
            status = "finished"
            try:
                while True:
                    if any(p.stat().st_size > OUTPUT_LIMIT for p in paths[1:]):
                        status = "output_limit"
                        break
                    if time.monotonic() - started > timeout:
                        status = "timeout"
                        break
                    try:
                        process.wait(timeout=0.02)
                        break
                    except subprocess.TimeoutExpired:
                        pass
            finally:
                # A child may retain output descriptors after the parent exits.
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait()
        if any(p.stat().st_size > OUTPUT_LIMIT for p in paths[1:]):
            status = "output_limit"
        def read_bounded(path):
            with path.open("rb") as stream:
                return stream.read(OUTPUT_LIMIT)
        return {"status": status, "returncode": process.returncode,
                "stdout": read_bounded(paths[1]), "stderr": read_bounded(paths[2]),
                "seconds": round(time.monotonic() - started, 4)}


def relative_path(value, allow_root=False):
    """Accept only portable paths relative to the assignment directory."""
    path = PurePosixPath(value)
    if (not value or path.is_absolute() or ".." in path.parts or
            "\\" in value or ":" in value or (not path.parts and not allow_root)):
        raise ValueError(f"expected a project-relative path: {value!r}")
    return path


def check_path(root, relative):
    path = root
    for part in relative.parts:
        path = path / part
        if path.is_symlink():
            raise ValueError(f"submission paths must not be symlinks: {relative}")
    return path


def collect(project, staging, required, optional, excludes):
    warnings = []
    copied = set()

    def excluded(relative):
        return (any(part in {".git", "__pycache__", ".DS_Store"} for part in relative.parts)
                or any(fnmatch.fnmatchcase(candidate.as_posix(), pattern)
                       for candidate in (relative, *relative.parents) if candidate.parts
                       for pattern in excludes))

    def copy(relative):
        if excluded(relative):
            return
        source = check_path(project, relative)
        destination = staging / relative
        if source.is_dir():
            destination.mkdir(parents=True, exist_ok=True)
            for child in sorted(source.iterdir()):
                copy(relative / child.name)
        elif source.is_file():
            if relative not in copied:
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)
                copied.add(relative)
        else:
            raise ValueError(f"not a regular file or directory: {relative}")

    for patterns, mandatory in ((required, True), (optional, False)):
        for pattern in patterns:
            relative_path(pattern)
            # Check literal ancestors even when a missing leaf makes glob return nothing.
            prefix = PurePosixPath()
            for part in PurePosixPath(pattern).parts:
                if any(char in part for char in "*?["):
                    break
                prefix /= part
                check_path(project, prefix)
            matches = [p for p in sorted(project.glob(pattern))
                       if not excluded(p.relative_to(project))]
            if mandatory and not matches:
                warnings.append(f"{pattern} is missing")
            for source in matches:
                relative = source.relative_to(project)
                copy(relative)
                if mandatory and source.is_file() and source.stat().st_size == 0:
                    warnings.append(f"{relative.as_posix()} is empty")
    if not copied:
        raise ValueError("no submission files selected; check the file list and exclusions")
    return warnings


def check_build(staging, build, directory, target, outputs):
    shutil.copytree(staging, build)
    cwd = build / relative_path(directory, allow_root=True)
    logs = []
    for step in ("clean", target):
        result = run_process(["make", step], cwd)
        logs.append(dict(target=step, **result))
        if result["status"] != "finished" or result["returncode"] != 0:
            return False, logs
    return all((build / relative_path(name)).is_file() for name in outputs), logs


def package(project, student, destination, *, files, optional=(), excludes=(),
            build_dir=None, build_target="all", build_outputs=(), diagnostics=None):
    project, destination = Path(project).resolve(), Path(destination).absolute()
    if not re.fullmatch(r"[0-9]{4}-[0-9]{5}", student):
        raise ValueError("student number must have the form 1234-56789")
    if destination.exists() or destination.is_symlink():
        raise ValueError(f"archive already exists: {destination}")
    if not project.is_dir():
        raise ValueError(f"project directory does not exist: {project}")
    for pattern in excludes:
        relative_path(pattern)
    if build_dir is not None:
        relative_path(build_dir, allow_root=True)
        if not build_target or build_target.startswith("-"):
            raise ValueError("invalid Make build target")
    for output in build_outputs:
        relative_path(output)
    if build_outputs and build_dir is None:
        raise ValueError("expected build outputs require a build directory")
    if diagnostics is not None:
        relative_path(diagnostics)
    with tempfile.TemporaryDirectory(prefix="course-package-") as directory:
        work = Path(directory)
        staging = work / "submission"
        staging.mkdir()
        warnings = collect(project, staging, files, optional, excludes)
        built, logs = None, []
        if build_dir is not None:
            built, logs = check_build(staging, work / "build", build_dir, build_target, build_outputs)
            if not built:
                warnings.append("clean build failed; the incomplete files are included for partial-credit review")
        if diagnostics is not None:
            report_path = staging / diagnostics
            if report_path.exists():
                raise ValueError(f"diagnostics would overwrite a selected file: {diagnostics}")
            report = {"build_ok": built, "warnings": warnings,
                      "build": [{**{k: v for k, v in r.items() if k not in {"stdout", "stderr"}},
                                 "stdout": r["stdout"].decode(errors="replace")[-8000:],
                                 "stderr": r["stderr"].decode(errors="replace")[-8000:]} for r in logs],
                      "note": "Packaging diagnostics only; not a correctness or grading result."}
            report_path.parent.mkdir(parents=True, exist_ok=True)
            report_path.write_text(json.dumps(report, indent=2) + "\n")
        archive = work / "submission.zip"
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as bundle:
            for path in sorted(staging.rglob("*")):
                bundle.write(path, path.relative_to(staging))
        with destination.open("xb") as output, archive.open("rb") as inp:
            shutil.copyfileobj(inp, output)
    for warning in warnings:
        print("WARNING: " + warning)
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-dir", type=Path, required=True)
    parser.add_argument("--name", required=True, help="assignment name used in the ZIP filename")
    parser.add_argument("--student", required=True)
    parser.add_argument("--file", action="append", default=[], help="required relative path or glob; repeatable")
    parser.add_argument("--optional", action="append", default=[], help="optional relative path or glob; repeatable")
    parser.add_argument("--exclude", action="append", default=[], help="relative exclusion pattern; repeatable")
    parser.add_argument("--build-dir", help="relative directory to run make clean and the build target")
    parser.add_argument("--build-target", default="all")
    parser.add_argument("--expect", action="append", default=[], help="expected build output relative to project root")
    parser.add_argument("--diagnostics", help="optional path for generated diagnostics inside the ZIP")
    args = parser.parse_args()
    try:
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", args.name):
            raise ValueError("invalid assignment name")
        if not re.fullmatch(r"[0-9]{4}-[0-9]{5}", args.student):
            raise ValueError("student number must have the form 1234-56789")
        project = args.project_dir.resolve()
        path = package(project, args.student, project / f"{args.name}_{args.student}.zip",
                       files=args.file, optional=args.optional, excludes=args.exclude,
                       build_dir=args.build_dir, build_target=args.build_target,
                       build_outputs=args.expect, diagnostics=args.diagnostics)
    except (ValueError, OSError) as exc:
        parser.exit(1, f"submission: {exc}\n")
    print(f"Created {path}\nUpload this ZIP to the course system. Packaging does not establish correctness.")


if __name__ == "__main__":
    main()
