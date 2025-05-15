%{
#include <stdio.h>
#include "y.tab.h"
%}

%%
void            { return VOID; }
int             { return INT; }
byte            { return BYTE; }
bool            { return BOOL; }
and             { return AND; }
or              { return OR; }
not             { return NOT; }
true            { return TRUE; }
false           { return FALSE; }
return          { return RETURN; }
if              { return IF; }
else            { return ELSE; }
while           { return WHILE; }
break           { return BREAK; }
continue        { return CONTINUE; }
;               { return SC; }
,               { return COMMA; }
\(              { return LPAREN; }
\)              { return RPAREN; }
\{              { return LBRACE; }
\}              { return RBRACE; }
\]              { return RBRACK; }
\[              { return LBRACK; }
=               { return ASSIGN; }
==|!=|<|>|<=|>= { return RELOP; }
\+|\-|\*|\/    { return BINOP; }
[a-zA-Z][a-zA-Z0-9]* { return ID; }
0|[1-9][0-9]*   { return NUM; }
0b|[1-9][0-9]*b { return NUM_B; }
"([^\n\r\"\\]|\\[rnt"\\])+" { return STRING; }
//[^\r\n]*[\r|\n|\r\n]? { /* skip single-line comments */ }
[ \t\r\n]+      { /* skip whitespace */ }
.               { output::errorLex(yylineno); return errorlex; }
%%

int yywrap() { return 1; }
