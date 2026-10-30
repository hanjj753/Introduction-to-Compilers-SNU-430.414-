%{
#include <stdio.h>
#include <stdlib.h>
%}

/* Declare the value type once, in the header shared with the scanner. */
%define api.value.type {char *}
%code provides {
int yylex(void);
int yylex_destroy(void);
void yyerror(const char *message);
}

%token NAME EQ AGE
/* Values discarded after a syntax or scanner error still need cleanup. */
%destructor { free($$); } NAME AGE

%%

file
    : file record
    | record
    ;

record
    : NAME EQ AGE
    {
        printf("%s is %s years old!!!\n", $1, $3);
        /* Successful reductions consume the two owned token strings. */
        free($1);
        free($3);
        $$ = NULL; /* Nonterminals do not retain token strings. */
    }
    ;

%%

int main(void)
{
    int status = yyparse();
    yylex_destroy();
    if (ferror(stdin)) {
        yyerror("cannot read input");
        status = 1;
    }
    if (fflush(stdout) == EOF || ferror(stdout)) {
        yyerror("cannot write output");
        status = 1;
    }
    return status == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}

void yyerror(const char *message)
{
    fprintf(stderr, "example: %s\n", message);
}
