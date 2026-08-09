%{
#include <stdio.h>
int yylex();
void yyerror(char *s);
%}
%token NUMBER
%left '+'
%%

calc:
    | calc expr '\n' { printf("Result = %d\n", $2); }
    ;
expr:
      expr '+' expr { $$ = $1 + $2; }
    | NUMBER        { $$ = $1; }
    ;
%%
int main() {
    yyparse();
    return 0;
}
void yyerror(char *s) { printf("Syntax Error: %s\n", s); }