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
        | Statements Statement { 
                
        }

Statement: LBRACE Statements RBRACE {
                $$ = std::dynamic_pointer_cast<ast::Statements>($2);
        }
        | Type ID SC {
                std::shared_ptr<ast::PrimitiveType> type = std::dynamic_pointer_cast<ast::PrimitiveType>($1);
                std::shared_ptr<ast::ID> id = std::dynamic_pointer_cast<ast::ID>($2);
                $$ = std::make_shared<ast::VarDecl>(id, type); 
         }
        | Type ID ASSIGN Exp SC {
                std::shared_ptr<ast::PrimitiveType> type = std::dynamic_pointer_cast<ast::PrimitiveType>($1);
                std::shared_ptr<ast::ID> id = std::dynamic_pointer_cast<ast::ID>($2);
                $$ = std::make_shared<ast::VarDecl>(id, type, $4); 
         }
        | ID ASSIGN Exp SC {
                std::shared_ptr<ast::ID> id = std::dynamic_pointer_cast<ast::ID>($1);
                std::shared_ptr<ast::Exp> exp = std::dynamic_pointer_cast<ast::Exp>($3);
                $$ = std::make_shared<ast::<Assign>(id,exp);
         }
        | ID LBRACK Exp RBRACK ASSIGN Exp SC { 
                std::shared_ptr<ast::ID> id = std::dynamic_pointer_cast<ast::ID>($1);
                std::shared_ptr<ast::Exp> index = std::dynamic_pointer_cast<ast::Exp>($3);
                std::shared_ptr<ast::Exp> value = std::dynamic_pointer_cast<ast::Exp>($6);
                $$ = std::make_shared<ast::<ArrayAssign>(id,value,index)
        }
        | Type ID LBRACK Exp RBRACK SC { 
                std::shared_ptr<ast::PrimitiveType> base_type = std::dynamic_pointer_cast<ast::PrimitiveType>($1);
                std::shared_ptr<ast::ID> id = std::dynamic_pointer_cast<ast::ID>($2);
                $$ = std::make_shared<ast::VarDecl>(
                    id, 
                    std::make_shared<ast::ArrayType>(base_type->type, $4)
                );
        }
        | Call SC {$$ = $1;}
        | Return SC {$$ = std::make_shared<ast::Return>();}
        | Return Exp SC {$$ = std::make_shared<ast::Return>(std::dynamic_pointer_cast<ast::Exp>($2));}
        | IF LPAREN Exp RPAREN Statement { }
        | IF LPAREN Exp RPAREN Statement ELSE Statement {

         }
        | While LPAREN Exp RPAREN Statement {
                std::shared_ptr<ast::Exp> expression =std::dynamic_pointer_cast<ast::Exp>($3);
                std::shared_ptr<ast::Statement> statement = std::dynamic_pointer_cast<ast::Statement>($5);
                $$ = std::make_shared<ast::While>(expression,statement);
         }
        | Break SC {$$ =   std::make_shared<ast::Break>();}
        | Continue SC {$$ = std::make_shared<ast::Continue>();}

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
                e_list->push_front(std::dynamic_pointer_cast<ast::Exp>($2));
                $$ = e_list;

        }

Type: Int {$$ = std::make_shared<ast::PrimitiveType>(ast::BuiltInType::INT);}
    | Byte {$$ = std::make_shared<ast::PrimitiveType>(ast::BuiltInType::BYTE);}
    | Bool {$$ = std::make_shared<ast::PrimitiveType>(ast::BuiltInType::BOOL);}

Exp: LPAREN Exp RPAREN {$$ = std::dynamic_pointer_cast<ast::Exp>($2);}
    | ID LBRACK Exp RBRACK {$$ = std::make_shared<ast::ArrayDereference>(std::dynamic_pointer_cast<ast::ID>($1),std::dynamic_pointer_cast<ast::Exp>($3));}
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
    | NOT Exp {$$ = std::make_shared<ast::Not>(std::dynamic_pointer_cast<ast::Exp>($2));}
    | Exp AND Exp {$$ = std::make_shared<ast::And>(std::dynamic_pointer_cast<ast::Exp>($1),std::dynamic_pointer_cast<ast::Exp>($3));}
    | Exp OR Exp {$$ = std::make_shared<ast::Or>(std::dynamic_pointer_cast<ast::Exp>($1),std::dynamic_pointer_cast<ast::Exp>($3));}
    | Exp EQ Exp {$$ = std::make_shared<ast::RelOp>(std::dynamic_pointer_cast<ast::Exp>($1),std::dynamic_pointer_cast<ast::Exp>($3),ast::RelOpType::EQ);}
    | Exp NE Exp {$$ = std::make_shared<ast::RelOp>(std::dynamic_pointer_cast<ast::Exp>($1),std::dynamic_pointer_cast<ast::Exp>($3),ast::RelOpType::NE);}
    | Exp LT Exp {$$ = std::make_shared<ast::RelOp>(std::dynamic_pointer_cast<ast::Exp>($1),std::dynamic_pointer_cast<ast::Exp>($3),ast::RelOpType::LT);}
    | Exp GT Exp {$$ = std::make_shared<ast::RelOp>(std::dynamic_pointer_cast<ast::Exp>($1),std::dynamic_pointer_cast<ast::Exp>($3),ast::RelOpType::GT);}
    | Exp LE Exp {$$ = std::make_shared<ast::RelOp>(std::dynamic_pointer_cast<ast::Exp>($1),std::dynamic_pointer_cast<ast::Exp>($3),ast::RelOpType::LE);}
    | Exp GE Exp {$$ = std::make_shared<ast::RelOp>(std::dynamic_pointer_cast<ast::Exp>($1),std::dynamic_pointer_cast<ast::Exp>($3),ast::RelOpType::GE);}
    | LPAREN Type RPAREN Exp {$$ = std::make_shared<ast::Cast>(std::dynamic_pointer_cast<ast::Exp>($4),std::dynamic_pointer_cast<ast::PrimitiveType>($2)); } 


;

// TODO: Define grammar here

%%

// TODO: Place any additional code here