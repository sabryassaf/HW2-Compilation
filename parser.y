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

Call: ID LPAREN ExpList RPAREN {
        std::shared_ptr<ast::ExpList> args = std::dynamic_pointer_cast<ast::ExpList>($3);
        std::shared_ptr<ast::ID> func_id = std::dynamic_pointer_cast<ast::ID>($1);
        $$ =  std::make_shared<ast::Call>(func_id,args);
 }
        | ID LPAREN RPAREN {
        std::shared_ptr<ast::ID> func_id = std::dynamic_pointer_cast<ast::ID>($1);
        $$ = std::make_shared<ast::Call>(func_id);
         }

ExpList: Exp {$$ = std::dynamic_pointer_cast<ast::ExpList>($1); }
        | Exp COMMA ExpList { 
                std::shared_ptr<ast::ExpList> e_list = std::dynamic_pointer_cast<ast::ExpList>($3);
                e_list->push_front($1);
                $$ = e_list;

        }

Type: Int {$$ = std::make_shared<ast::PrimitiveType>(ast::BuiltInType::INT);}
    | Byte {$$ = std::make_shared<ast::PrimitiveType>(ast::BuiltInType::BYTE);}
    | Bool {$$ = std::make_shared<ast::PrimitiveType>(ast::BuiltInType::BOOL);}

Exp: LPAREN Exp RPAREN {$$ = $2;}
    | ID LBRACK Exp RBRACK {$$ = std::make_shared<ast::ArrayDereference>(std::dynamic_pointer_cast<ast::ID>($1),$3);}
    | Exp DIV Exp {$$ = std::make_shared<ast::BinOp>($1,$3,ast::BinOpType::DIV);}
    | Exp MUL Exp {$$ = std::make_shared<ast::BinOp>($1,$3,ast::BinOpType::MUL);}
    | Exp SUB Exp {$$ = std::make_shared<ast::BinOp>($1,$3,ast::BinOpType::SUB);}
    | Exp ADD Exp {$$ = std::make_shared<ast::BinOp>($1,$3,ast::BinOpType::ADD);}
    | ID {$$ = $1;}
    | Call {$$ = $1;}
    | NUM {$$ = $1;}
    | NUMB {$$ = $1;}
    | STRING {$$ = $1;}
    | TRUE {$$ = std::make_shared<ast::Bool>(true); }
    | FALSE {$$ = std::make_shared<ast::Bool>(false); }
    | NOT Exp {$$ = std::make_shared<ast::Not>($2);}
    | Exp AND Exp {$$ = std::make_shared<ast::And>($1,$3);}
    | Exp OR Exp {$$ = std::make_shared<ast::Or>($1,$3);}
    | Exp EQ Exp {$$ = std::make_shared<ast::RelOp>($1,$3,ast::RelOpType::EQ);}
    | Exp NE Exp {$$ = std::make_shared<ast::RelOp>($1,$3,ast::RelOpType::NE);}
    | Exp LT Exp {$$ = std::make_shared<ast::RelOp>($1,$3,ast::RelOpType::LT);}
    | Exp GT Exp {$$ = std::make_shared<ast::RelOp>($1,$3,ast::RelOpType::GT);}
    | Exp LE Exp {$$ = std::make_shared<ast::RelOp>($1,$3,ast::RelOpType::LE);}
    | Exp GE Exp {$$ = std::make_shared<ast::RelOp>($1,$3,ast::RelOpType::GE);}
    | LPAREN Type RPAREN Exp {$$ = std::make_shared<ast::Cast>($4,std::dynamic_pointer_cast<ast::PrimitiveType>($2)); } 

    // I don't think we need to cast the EXP objects because they are already Exp, opposite to RPAREN for example which needs to be specified 
    // - yet better to check
;

// TODO: Define grammar here

%%

// TODO: Place any additional code here