#include "subc.h"

_Noreturn void fail(const char *message)
{
    fprintf(stderr, "subc: %s\n", message);
    exit(EXIT_FAILURE);
}

void emit_token(const char *kind, const char *text)
{
    if (printf("%s\t%s\n", kind, text) < 0)
        fail("cannot write output");
}

void emit_name(const char *text, size_t length)
{
#ifdef SUBC_SCANNER_CHECK
    (void)text;
    (void)length;
    fail("name output is outside the scanner-only check; run make test for names");
#else
    Symbol *symbol = enter(TOKEN_IDENTIFIER, text, length);
    if (!symbol)
        fail("enter() is not implemented or could not allocate an entry");
    symbol->count++;
    if (printf("%s\t%s\t%zu\n",
               symbol->kind == TOKEN_KEYWORD ? "KEY" : "ID",
               symbol->name, symbol->count) < 0)
        fail("cannot write output");
#endif
}

int main(int argc, char **argv)
{
#ifndef SUBC_SCANNER_CHECK
    static const char *const keywords[] = {
        "break", "char", "continue", "else", "float", "for", "if",
        "int", "return", "struct", "while", "NULL"
    };
#endif
    if (argc > 2) {
        fprintf(stderr, "usage: subc [input_file]\n");
        return EXIT_FAILURE;
    }
    yyin = argc == 2 ? fopen(argv[1], "rb") : stdin;
    if (!yyin) {
        perror("subc: cannot open input");
        return EXIT_FAILURE;
    }
#ifndef SUBC_SCANNER_CHECK
    for (size_t i = 0; i < sizeof(keywords) / sizeof(keywords[0]); i++) {
        if (!enter(TOKEN_KEYWORD, keywords[i], strlen(keywords[i])))
            fail("enter() is not implemented or could not allocate an entry");
    }
#endif
    scan();
    if (ferror(yyin))
        fail("cannot read input");
    if (argc == 2 && fclose(yyin) != 0)
        fail("cannot close input");
    /* Check/close the driver-owned stream before Flex resets yyin to NULL. */
    yylex_destroy();
#ifndef SUBC_SCANNER_CHECK
    symbols_destroy();
#endif
    if (fflush(stdout) != 0)
        fail("cannot write output");
    return EXIT_SUCCESS;
}
