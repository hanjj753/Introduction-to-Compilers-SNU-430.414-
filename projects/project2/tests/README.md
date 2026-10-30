# Local tests

The starter grammar is intentionally incomplete. Complete it and copy or
implement your name table before expecting a successful build and test run.
The checker uses Python's standard library; no additional packages are needed.

Run these commands from `intcmp/projects/project2/` in the course container:

~~~sh
make test                 # build and run all test pairs
make test CASE=sample     # build and run just sample.c against sample.out
~~~

## Provided example

`sample.c` is the example input, and `sample.out` is its expected reduction
trace. The example illustrates the output contract; it does not cover the
entire language.

## Add your own tests

1. Create `tests/my-case.c` containing a small, valid subC program.
2. Write its expected reduction trace in `tests/my-case.out`.
3. Run `make test CASE=my-case`, or use `make test` to run every pair.

Use matching names directly inside `tests/`; subdirectories are not searched.
No registration or Makefile edit is needed. `CASE` is the filename stem,
without a path or extension. A missing partner or unknown case is an error.
Additional tests are optional and are not submitted.

The checker never changes your input or expected-output files.

For an already built executable, you can also run the checker directly:

~~~sh
python3 tests/test.py --case my-case
~~~

## Read results

Each pair reports `PASS` or `FAIL`, followed by a total. The checker requires
exit status zero, empty stderr, and stdout identical to the `.out` file.
Each run has a two-second timeout and a 16 MiB limit for each of stdout and
stderr. Nonzero exits, signals, unexpected stderr, timeouts, output-limit
failures, and missing files are reported separately.

On an output mismatch, the checker prints a diff and a byte-string excerpt:
`\n` denotes LF, `\r` denotes carriage return, and `\t` denotes TAB in that
excerpt. It also identifies a missing final LF. These are descriptions of
bytes, not text to put into your expected output. Long diffs are abbreviated;
large files show an excerpt around the first differing byte.

For every completed run, the actual output and stderr are saved as:

~~~text
test-results/my-case.actual
test-results/my-case.stderr
~~~

Timeouts and output-limit failures save the output captured before stopping,
up to 16 MiB per stream. Rerunning a case replaces
its generated results, including after a failure; results for other cases
remain from their last run. You can compare `.actual` with `tests/my-case.out`
in VS Code to inspect the full trace. The `test-results/` directory is generated
and is not part of the submission.
