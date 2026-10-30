PYTHON = python3
# Pass the optional test name as data, without inserting it into a shell command.
export CASE

# Submission paths are relative to this project. Directories include their contents.
SUBMIT_NAME := project2
SUBMIT_FILES := src **/report.pdf
SUBMIT_OPTIONAL :=
SUBMIT_EXCLUDE := src/*.o src/*.d src/*.a src/*.so src/lex.yy.c src/subc src/*.tab.c src/*.tab.h src/*.output
SUBMIT_BUILD_DIR := src
SUBMIT_BUILD_TARGET := all
SUBMIT_BUILD_OUTPUTS := src/subc
SUBMIT_DIAGNOSTICS := packaging.json

.PHONY: all clean test submit
all:
	$(MAKE) -C src all

test: all
	$(PYTHON) tests/test.py

submit:
	@test -n "$(STUDENT_ID)" || { echo "Usage: make submit STUDENT_ID=1234-56789" >&2; exit 1; }
	@test -f ../../scripts/submit.py || { echo "Common submission tool missing. Place this project under intcmp/projects/ from the environment package." >&2; exit 1; }
	@$(PYTHON) ../../scripts/submit.py --project-dir "$(CURDIR)" --name "$(SUBMIT_NAME)" --student "$(STUDENT_ID)" \
		$(foreach path,$(SUBMIT_FILES),--file "$(path)") \
		$(foreach path,$(SUBMIT_OPTIONAL),--optional "$(path)") \
		$(foreach path,$(SUBMIT_EXCLUDE),--exclude "$(path)") \
		$(if $(SUBMIT_BUILD_DIR),--build-dir "$(SUBMIT_BUILD_DIR)" --build-target "$(SUBMIT_BUILD_TARGET)") \
		$(if $(SUBMIT_BUILD_DIR),$(foreach path,$(SUBMIT_BUILD_OUTPUTS),--expect "$(path)")) \
		$(if $(SUBMIT_DIAGNOSTICS),--diagnostics "$(SUBMIT_DIAGNOSTICS)")

clean:
	$(MAKE) -C src clean
