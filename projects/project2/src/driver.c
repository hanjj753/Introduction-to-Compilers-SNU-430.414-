#include "subc.h"

_Noreturn void fail(const char *message)
{
    fprintf(stderr, "subc: %s\n", message);
    exit(EXIT_FAILURE);
}

void reduce(const char *production)
{
    if (printf("%s\n", production) < 0)
        fail("cannot write output");
}

void yyerror(const char *message)
{
    fprintf(stderr, "subc: %s at line %d, token '%s'\n",
            message, get_lineno(), yyget_text());
}

int main(int argc, char **argv)
{
    static const char *const keywords[] = {
        "break", "char", "continue", "else", "for", "if",
        "int", "return", "struct", "while", "NULL"
    };

    if (argc > 2) {
        fprintf(stderr, "usage: subc [input_file]\n");
        return EXIT_FAILURE;
    }

    yyin = argc == 2 ? fopen(argv[1], "rb") : stdin;
    if (!yyin) {
        perror("subc: cannot open input");
        return EXIT_FAILURE;
    }

    for (size_t i = 0; i < sizeof(keywords) / sizeof(keywords[0]); i++) {
        if (!enter(TOKEN_KEYWORD, keywords[i], strlen(keywords[i])))
            fail("enter() is not implemented or could not allocate an entry");
    }

    scanner_begin();
    int status = yyparse();

    if (ferror(yyin))
        fail("cannot read input");
    if (argc == 2 && fclose(yyin) != 0)
        fail("cannot close input");
    yylex_destroy();
    symbols_destroy();

    if (fflush(stdout) != 0)
        fail("cannot write output");
    return status == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
