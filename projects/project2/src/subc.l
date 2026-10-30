%option noyywrap nodefault noinput nounput never-interactive yylineno
%{
#include "subc.h"
#include "subc.tab.h"
static size_t comment_depth;
%}

%x NORMAL COMMENT
letter        [A-Za-z_]
digit         [0-9]
id            {letter}({letter}|{digit})*
integer_const ([1-9]{digit}*)|"0"
whitespace    [ \t\r\n]+
special_char  \\[nt]

%%

  /* Complete keyword rules. Return Bison tokens to the parser. */
<NORMAL>"int"|"char"             { return TYPE; }
<NORMAL>"struct"                 { return STRUCT; }

  /* stringVal borrows scanner or table storage; the parser does not own it.
   * Reduction actions need not read or copy lexemes. Do not free these pointers
   * or retain them for later dereferencing.
   */
<NORMAL>{id} {
    Symbol *symbol = enter(TOKEN_IDENTIFIER, yytext, (size_t)yyleng);
    if (!symbol)
        fail("enter() is not implemented or could not allocate an entry");
    yylval.stringVal = symbol->name;
    return ID;
}
<NORMAL>{integer_const} {
    yylval.intVal = atoi(yytext);
    return INTEGER_CONST;
}
  /* Supplied character and string literal rules. */
<NORMAL>\"({special_char}|[^\\\"\n])*\" {
    yylval.stringVal = yytext;
    return STRING;
}
<NORMAL>'({special_char}|[^\\'\n])' {
    yylval.stringVal = yytext;
    return CHAR_CONST;
}

  /* Complete operator and punctuation rules. */
<NORMAL>","                      { return ','; }
<NORMAL>";"                      { return ';'; }

  /* Supplied whitespace, nested comments, diagnostics, and EOF handling. */
<NORMAL>{whitespace}             { /* No token. */ }
<NORMAL>"/*"                     { comment_depth = 1; BEGIN COMMENT; }
<COMMENT>"/*"                    { comment_depth++; }
<COMMENT>"*/"                    { if (--comment_depth == 0) BEGIN NORMAL; }
<COMMENT>(.|\n)                  { /* No token. */ }
<COMMENT><<EOF>>                 { fail("unterminated comment"); }
<NORMAL>.                       { fail("scanner rule missing or unsupported character"); }
<INITIAL>(.|\n)                  { fail("scanner did not enter NORMAL state"); }
<NORMAL><<EOF>>                  { return 0; }

%%

/* The driver initializes the scanner once, then yyparse() calls yylex(). */
void scanner_begin(void)
{
    comment_depth = 0;
    yylineno = 1;
    BEGIN NORMAL;
}

int get_lineno(void)
{
    return yylineno;
}
