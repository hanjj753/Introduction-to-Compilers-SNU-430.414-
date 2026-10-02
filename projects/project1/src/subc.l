%option noyywrap nodefault noinput nounput never-interactive
%{
/* C declarations copied into the generated scanner. */
#include "subc.h"
int comment_count = 0;
/* TODO: declare C state here, including the comment-depth counter. */
%}

/* Definitions: token patterns and start conditions. */
%x NORMAL COMMENT
letter [A-Za-z_]

/* TODO: define numeric, name, and whitespace patterns. */
digit [0-9]
name {letter}({letter}|{digit})*
whitespace [ \t\r\n]
integer-constant [1-9]{digit}*|0
float-constant {digit}+\.{digit}*([eE][+-]?{digit}+)?

keywords break|char|continue|else|float|for|if|int|return|struct|while|NULL
operators \(|\)|\[|\]|\{|\}|->|\.|\,|\.\.|!|\+\+|--|\*|\/|%|\+|-|<|<=|>|>=|==|!=|&|&&|\|\||;|=

%%

  /* Rules: pattern/action pairs. Comments in this section must be indented. */
  /* TODO: implement rules for NORMAL and COMMENT.
   * Emit OP/INT/F tokens with emit_token(), and names with
   * emit_name(yytext, (size_t)yyleng), which also increments counts.
   */

<COMMENT>. { }
<COMMENT>{whitespace} { }
<NORMAL>\/\* { 
    BEGIN COMMENT;
    comment_count++; }
<COMMENT>\/\* { comment_count++;}
<COMMENT>\*\/ { 
    comment_count--;
    if (comment_count == 0) BEGIN NORMAL; }

<NORMAL>{keywords} {
    Symbol *symbol = enter(TOKEN_KEYWORD, yytext, yyleng);
    if (!symbol) fail("enter() is not implemented or could not allocate an entry");
    symbol->count++;
    if (printf("%s\t%s\t%zu\n", "KEY", yytext, symbol->count) < 0) fail("cannot write output");
}
<NORMAL>{name} {emit_name(yytext, (size_t)yyleng);}

<NORMAL>{whitespace} { }

<NORMAL>\.\./{integer-constant} {emit_token("OP", yytext);}
<NORMAL>{operators} { emit_token("OP", yytext); }

<NORMAL>{integer-constant}/(\.\.)* { emit_token("INT", yytext); }
<NORMAL>{float-constant} { emit_token("F", yytext); }

<NORMAL,COMMENT>(.|\n) { fail("scanner rule missing or unsupported character"); }
<INITIAL>(.|\n)        { fail("scanner did not enter NORMAL state"); }
<COMMENT><<EOF>>       { fail("unterminated comment"); }
<NORMAL><<EOF>>        { return 0; }

%%

/* User code. The supplied driver calls scan() after initializing keywords. */

void scan(void)
{
    BEGIN NORMAL;
    yylex();
}
