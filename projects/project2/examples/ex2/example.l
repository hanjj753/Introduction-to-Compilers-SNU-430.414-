%option noyywrap nodefault noinput nounput never-interactive
%{
#include "example.tab.h"
#include <errno.h>
#include <stdlib.h>
%}

number      [0-9]+
whitespace  [ \t\r]+

%%

\n { return ENTER; }
{whitespace} { /* No token. */ }
{number} {
    errno = 0;
    yylval.floatval = strtof(yytext, NULL);
    if (errno == ERANGE) {
        yyerror("number out of range");
        return YYerror;
    }
    return FLOAT;
}
[-+*/] { return yytext[0]; }
. {
    yyerror("unsupported character");
    return YYerror;
}

%%
