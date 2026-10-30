%option noyywrap nodefault noinput nounput never-interactive
%{
#include "example.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Token strings belong to the parser; yytext is reused by the scanner. */
static char *copy_text(const char *text, size_t length)
{
    char *copy = malloc(length + 1);
    if (copy) {
        memcpy(copy, text, length);
        copy[length] = '\0';
    }
    return copy;
}
%}

name        [A-Za-z]+
age         [0-9]+
whitespace  [ \t\r\n]+

%%

{name} {
    yylval = copy_text(yytext, (size_t)yyleng);
    if (!yylval) {
        yyerror("out of memory");
        return YYerror;
    }
    printf("String : %s\n", yytext);
    return NAME;
}
"=" { return EQ; }
{age} {
    yylval = copy_text(yytext, (size_t)yyleng);
    if (!yylval) {
        yyerror("out of memory");
        return YYerror;
    }
    return AGE;
}
{whitespace} { /* No token. */ }
. {
    yyerror("unsupported character");
    /* The diagnostic is already printed; let Bison discard owned values. */
    return YYerror;
}

%%
