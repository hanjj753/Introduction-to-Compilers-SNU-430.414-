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

/* Tokens and Types */
%token            TYPE STRUCT
%token<stringVal> ID CHAR_CONST STRING
%token<intVal>    INTEGER_CONST

/* Precedences and Associativities */
%left ','
%left STRUCTOP

%start program

%%

/* Add the remaining productions and actions below, using the handout.
 * Preserve productions; resolve conflicts with precedence declarations / %prec.
 */
program
  : ext_def_list
  {
    reduce("program->ext_def_list");
  }
  ;

ext_def_list
  : ext_def_list ext_def
  {
    reduce("ext_def_list->ext_def_list ext_def");
  }
  | %empty 
  {
    reduce("ext_def_list->epsilon");
  }
  ;

unary
  : INTEGER_CONST
  {
    reduce("unary->INTEGER_CONST");
  }
  | CHAR_CONST
  {
    reduce("unary->CHAR_CONST");
  }
  | STRING
  {
    reduce("unary->STRING");
  }
  | ID
  {
    reduce("unary->ID");
  }
  ;

%%
