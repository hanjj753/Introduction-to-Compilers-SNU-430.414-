%{
#include <stdio.h>
#include <stdlib.h>
%}

%code provides {
int yylex(void);
int yylex_destroy(void);
void yyerror(const char *message);
}
%union {
    float floatval;
}

%token ENTER
%token<floatval> FLOAT
%type<floatval> binary

%left '+' '-'
%left '*' '/'

%%

expr
    : binary ENTER
    {
        printf("Result = %.1f\n", $1);
        /* This example handles one line; use Bison's normal cleanup path. */
        YYACCEPT;
    }
    ;

binary
    : binary '+' binary
    {
        $$ = $1 + $3;
        printf("%.1f = %.1f + %.1f\n", $$, $1, $3);
    }
    | binary '-' binary
    {
        $$ = $1 - $3;
        printf("%.1f = %.1f - %.1f\n", $$, $1, $3);
    }
    | binary '*' binary
    {
        $$ = $1 * $3;
        printf("%.1f = %.1f * %.1f\n", $$, $1, $3);
    }
    | binary '/' binary
    {
        if ($3 == 0.0f) {
            yyerror("division by zero");
            YYABORT;
        }
        $$ = $1 / $3;
        printf("%.1f = %.1f / %.1f\n", $$, $1, $3);
    }
    | FLOAT { $$ = $1; }
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
