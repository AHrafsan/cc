%{
#include <string.h>
#include "opt.tab.h"
%}
%%
[0-9]+               { yylval.ival = atoi(yytext); return NUMBER; }
[a-zA-Z][a-zA-Z0-9]* { yylval.sval = strdup (yytext); return IDENTIFIER; }
[+\-*/=\n]           { return yytext [0]; }
[ \t]                {}
.                    {}
%%
int yywrap() { return 1; }