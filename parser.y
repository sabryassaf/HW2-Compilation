%{

#include "nodes.hpp"
#include "output.hpp"

// bison declarations
extern int yylineno;
extern int yylex();

void yyerror(const char*);

// root of the AST, set by the parser and used by other parts of the compiler
std::shared_ptr<ast::Node> program;

using namespace std;

// TODO: Place any additional declarations here
%}

// TODO: Define tokens here

// TODO: Define precedence and associativity here

%%

// While reducing the start variable, set the root of the AST
Program:  Funcs { program = $1; }
Funcs: /* empty */ { }
        | FuncDecl Funcs { }
FuncDecl: RetType ID LPAREN Formals RPAREN LBRACE Statements RBRACE { }
RetType: Type { }
RetType: Void { }
Formals: empty { }
        | FormalsList { }

FormalsList: FormalDecl { }
        | FormalDecl COMMA FormalsList { }
FormalDecl: Type ID { }
Statements: Statement { }
        | Statement Statements { }
Statement: LBRACE Statements RBRACE { }
        | Type ID SC { }
        | Type ID ASSIGN Exp SC { }
        | ID ASSIGN Exp SC { }
        | ID LBRACK Exp RBRACK ASSIGN Exp SC { }
        | Type ID LBRACK Exp RBRACK SC { }
        | Call SC { }
        | Return SC { }
        | Return Exp SC { }
        | IF LPAREN Exp RPAREN Statement { }
        | IF LPAREN Exp RPAREN Statement ELSE Statement { }
        | While LPAREN Exp RPAREN Statement { }
        | Break SC { }
        | Continue SC { }
Call: ID LPAREN ExpList RPAREN { }
        | ID LPAREN RPAREN { }
ExpList: Exp { }
        | Exp COMMA ExpList { }
Type: Int { }
    | Byte { }
    | Bool { }
Exp: LPAREN Exp RPAREN { }
    | ID LBRACK Exp RBRACK { }
    | Exp BINOP Exp { }
    | ID { }
    | Call { }
    | NUM { }
    | NUMB { }
    | STRING { }
    | TRUE { }
    | FALSE { }
    | NOT Exp { }
    | Exp AND Exp { }
    | Exp OR Exp { }
    | Exp RELOP Exp { }
    | LPAREN Type RPAREN Exp { }
;

// TODO: Define grammar here

%%

// TODO: Place any additional code here