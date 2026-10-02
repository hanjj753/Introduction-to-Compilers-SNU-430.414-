#!/usr/bin/env bash
# Check the installed tools independently of any unfinished assignment.
set -euo pipefail

source /etc/os-release
if [[ "$ID" != ubuntu || "$VERSION_ID" != 26.04 ]]; then
    echo "Expected Ubuntu 26.04; found $PRETTY_NAME" >&2
    exit 1
fi
printf '%s (%s)\n' "$PRETTY_NAME" "$(uname -m)"
for tool in gcc flex bison make python3 gdb valgrind git; do
    "$tool" --version | sed -n '1p'
done

check_dir=$(mktemp -d)
trap 'rm -rf "$check_dir"' EXIT
cd "$check_dir"

cat > parser.y <<'EOF'
%{
#include <stdio.h>
int yylex(void);
int yylex_destroy(void);
void yyerror(const char *message) { fprintf(stderr, "%s\n", message); }
%}
%token NUMBER
%%
input: NUMBER { printf("%d\n", $1); };
%%
int main(void) {
    int status = yyparse();
    yylex_destroy();
    return status;
}
EOF
cat > scanner.l <<'EOF'
%option noyywrap noinput nounput never-interactive
%{
#include <stdlib.h>
#include "parser.tab.h"
%}
%%
[0-9]+ { yylval = atoi(yytext); return NUMBER; }
[ \t\r\n]+ ;
. { return yytext[0]; }
%%
EOF
bison -d -Wcounterexamples parser.y
flex scanner.l
gcc -std=c11 -Wall -Wextra -Wpedantic -g parser.tab.c lex.yy.c -lfl -o scanner
printf '42\n' > input.txt
./scanner < input.txt > output.txt
cmp input.txt output.txt

gdb --batch -ex 'break main' -ex 'run < input.txt' -ex continue \
    --args ./scanner > debug.log 2>&1
if ! grep -q 'Breakpoint 1, main' debug.log || ! grep -q 'exited normally' debug.log; then
    cat debug.log >&2
    exit 1
fi
valgrind --quiet --leak-check=full --error-exitcode=1 \
    ./scanner < input.txt > output.txt
cmp input.txt output.txt
zip -q example.zip output.txt
unzip -p example.zip output.txt | cmp - input.txt
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile
with ZipFile("example.zip") as archive:
    assert archive.read("output.txt") == Path("input.txt").read_bytes()
PY
test "$(printf '2 + 3\n' | bc)" = 5
echo 'Environment check passed (C, Flex, Bison, debugger, memory checker, ZIP, Python).'
