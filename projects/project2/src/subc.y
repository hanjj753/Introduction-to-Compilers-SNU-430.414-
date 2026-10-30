/*
 * File Name    : subc.y
 * Description  : a skeleton bison input
 * 
 * Course       : Introduction to Compilers
 * Dept. of Electrical and Computer Engineering, Seoul National University
 */

%{
/* Prologue section */
#include "subc.h"

/* Interfaces and the supplied reduce() are declared in subc.h. */
%}

/* Bison declarations section */

/* yylval types */
%union {
  int   intVal;
  char  *stringVal;
}

/* Tokens and Types - 토큰을 선언하면서 위 union에서 어떤 type을 쓸지 선택 */
%token            TYPE STRUCT RETURN SYM_NULL IF ELSE WHILE FOR BREAK CONTINUE LOGICAL_OR LOGICAL_AND RELOP EQUOP INCOP DECOP STRUCTOP
%token<stringVal> ID CHAR_CONST STRING
%token<intVal>    INTEGER_CONST

/* Precedences and Associativities - 아래로 갈수록 높은 우선순위, 같은 줄은 같은 우선순위*/
%left ','
%right '='
%left LOGICAL_OR
%left LOGICAL_AND
%left EQUOP
%left RELOP
%left '+' '-'
%left '*' '/' '%'
%right '!' '&'
%left STRUCTOP

%start program

%%

/* Add the remaining productions and actions below, using the handout.
 * Preserve productions; resolve conflicts with precedence declarations / %prec.
 */
program
  : ext_def_list                                           { reduce("program->ext_def_list");}
  ;

ext_def_list
  : ext_def_list ext_def                                  { reduce("ext_def_list->ext_def_list ext_def"); }
  | %empty                                                { reduce("ext_def_list->epsilon"); }
  ;

ext_def
  : type_specifier pointers ID ';'                        { reduce("ext_def->type_specifier pointers ID ';'");}
  | type_specifier pointers ID '[' INTEGER_CONST ']' ';'  { reduce("ext_def->type_specifier pointers ID '[' INTEGER_CONST ']' ';'");}
  | struct_specifier ';'                                  { reduce("ext_def->struct_specifier ';'");}
  | func_decl compound_stmt                               { reduce("ext_def->func_decl compound_stmt");}
  ;

type_specifier
  : TYPE                                                  { reduce("type_specifier->TYPE");}
  | struct_specifier                                      { reduce("type_specifier->struct_specifier");}
  ;

struct_specifier
  : STRUCT ID '{' def_list '}'                            { reduce("struct_specifier->STRUCT ID '{' def_list '}'");}
  | STRUCT ID                                             { reduce("struct_specifier->STRUCT ID");}
  ;

func_decl
  : type_specifier pointers ID '(' ')'                    { reduce("func_decl->type_specifier pointers ID '(' ')'");}
  | type_specifier pointers ID '(' param_list ')'         { reduce("func_decl->type_specifier pointers ID '(' param_list ')'");}
  ;

pointers
  : '*'                                                   { reduce("pointers->'*'");}
  | %empty                                                { reduce("pointers->epsilon");}
  ;

/* func param */
param_list
  : param_decl                                            { reduce("param_list->param_decl");}
  | param_list ',' param_decl                             { reduce("param_list->param_list ',' param_decl");}
  ;

param_decl
  : type_specifier pointers ID                            { reduce("param_decl->type_specifier pointers ID");}
  | type_specifier pointers ID '[' INTEGER_CONST ']'      { reduce("param_decl->type_specifier pointers ID '[' INTEGER_CONST ']'");}
  ;

/* 함수 안에 지역 변수*/
def_list
  : def_list def                                          { reduce("def_list->def_list def");}
  | %empty                                                { reduce("def_list->epsilon");}
  ;

def
  : type_specifier pointers ID ';'                        { reduce("def->type_specifier pointers ID ';'");}
  | type_specifier pointers ID '[' INTEGER_CONST ']' ';'  { reduce("def->type_specifier pointers ID '[' INTEGER_CONST ']' ';'");}
  ;

/* 함수 안에 지역 변수 할당 외 다른 부분, 코드, return 등 */
compound_stmt
  : '{' def_list stmt_list '}'                            { reduce("compound_stmt->'{' def_list stmt_list '}'");}
  ;

stmt_list
  : stmt_list stmt                                        { reduce("stmt_list->stmt_list stmt");}
  | %empty                                                { reduce("stmt_list->epsilon");}
  ;

stmt
  : expr ';'                                              { reduce("stmt->expr ';'");}
  | compound_stmt                                         { reduce("stmt->compound_stmt");}
  | RETURN expr ';'                                       { reduce("stmt->RETURN expr ';'");}
  | ';'                                                   { reduce("stmt->';'");}
  | IF '(' expr ')' stmt                                  { reduce("stmt->IF '(' expr ')' stmt");}
  | IF '(' expr ')' stmt ELSE stmt                        { reduce("stmt->IF '(' expr ')' stmt ELSE stmt");}
  | WHILE '(' expr ')' stmt                               { reduce("stmt->WHILE '(' expr ')' stmt");}
  | FOR '(' expr_e ';' expr_e ';' expr_e ')' stmt         { reduce("stmt->FOR '(' expr_e ';' expr_e ';' expr_e ')' stmt");}
  | BREAK ';'                                             { reduce("stmt->BREAK ';'");}
  | CONTINUE ';'                                          { reduce("stmt->CONTINUE ';'");}
  ;

expr_e
  : expr                                                  { reduce("expr_e->expr");}
  | %empty                                                { reduce("expr_e->epsilon");}
  ;

expr
  : unary '=' expr                                       { reduce("expr->unary '=' expr");}
  | binary                                                { reduce("expr->binary");}
  ;

binary
  : binary RELOP binary                                   { reduce("binary->binary RELOP binary");}
  | binary EQUOP binary                                   { reduce("binary->binary EQUOP binary");}
  | binary '+' binary                                     { reduce("binary->binary '+' binary");}
  | binary '-' binary                                     { reduce("binary->binary '-' binary");}
  | binary '*' binary                                     { reduce("binary->binary '*' binary");}
  | binary '/' binary                                     { reduce("binary->binary '/' binary");}
  | binary '%' binary                                     { reduce("binary->binary '%' binary");}
  | unary %prec '='                                       { reduce("binary->unary");}
  | binary LOGICAL_AND binary                             { reduce("binary->binary LOGICAL_AND binary");}
  | binary LOGICAL_OR binary                              { reduce("binary->binary LOGICAL_OR binary");}
  ;

unary
  : '(' expr ')'                                          { reduce("unary->'(' expr ')'");}
  | INTEGER_CONST                                         { reduce("unary->INTEGER_CONST");}
  | CHAR_CONST                                            { reduce("unary->CHAR_CONST");}
  | STRING                                                { reduce("unary->STRING");}
  | ID                                                    { reduce("unary->ID");}
  | '-' unary %prec '!'                                   { reduce("unary->'-' unary");}
  | '!' unary                                             { reduce("unary->'!' unary");}
  | unary INCOP %prec STRUCTOP                              { reduce("unary->unary INCOP");}
  | unary DECOP %prec STRUCTOP                           { reduce("unary->unary DECOP");}
  | INCOP unary %prec '!'                                 { reduce("unary->INCOP unary");}
  | DECOP unary %prec '!'                                 { reduce("unary->DECOP unary");}
  | '&' unary                                             { reduce("unary->'&' unary");}
  | '*' unary %prec '!'                                   { reduce("unary->'*' unary");}
  | unary '[' expr ']' %prec STRUCTOP                         { reduce("unary->unary '[' expr ']'");}
  | unary '.' ID %prec STRUCTOP                               { reduce("unary->unary '.' ID");}
  | unary STRUCTOP ID                                     { reduce("unary->unary STRUCTOP ID");}
  | unary '(' args ')' %prec STRUCTOP                         { reduce("unary->unary '(' args ')'");}
  | unary '(' ')'                                         { reduce("unary->unary '(' ')'");}
  | SYM_NULL                                              { reduce("unary->SYM_NULL");}
  ;


args
  : expr                                                  { reduce("args->expr");}
  | args ',' expr                                         { reduce("args->args ',' expr");}
  ;

%%
