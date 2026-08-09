%{
#include "demo.tab.h"
%}

.       { /* ignore unknown characters */ }
[0-9]+  { yylval = atoi(yytext); return NUMBER; }
[+\n]   { return yytext[0]; }
[ \t]   { /* skip whitespace */ }
%%
int yywrap() { return 1; }