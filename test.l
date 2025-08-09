%{
#include "test.tab.h"
#include <string.h>
%}

%%

mytype              { return MYTYPE; }
show                { return SHOW; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); return IDENTIFIER; }
[0-9]+              { yylval.num = atoi(yytext); return NUMBER; }
"&&"                { return AND; }
"||"                { return OR; }
"!"                 { return NOT; }
"<<"                { return LSHIFT; }
">>"                { return RSHIFT; }
"&"                 { return BAND; }
"|"                 { return BOR; }
"^"                 { return BXOR; }
"~"                 { return BNOT; }
"+"                 { return PLUS; }
"-"                 { return MINUS; }
"*"                 { return TIMES; }
"/"                 { return DIVIDE; }
"="                 { return '='; }
","                 { return ','; }
";"                 { return ';'; }
"("                 { return '('; }
")"                 { return ')'; }
[ \t\n]+            { /* Ignore whitespace */ }
.                   { return yytext[0]; }

%%

int yywrap(void) {
    return 1;
}
 