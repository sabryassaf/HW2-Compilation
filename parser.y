%{

#include "nodes.hpp"
#include "output.hpp"
#include <iostream>

// bison declarations
extern int yylineno;
extern int yylex();

void yyerror(const char*);

// root of the AST, set by the parser and used by other parts of the compiler
std::shared_ptr<ast::Node> program;

using namespace std;

// TODO: Place any additional declarations here
%}

%code requires {
    #include <memory> // For std::shared_ptr
    #include "nodes.hpp" // For ast::Node
}

%define api.value.type {std::shared_ptr<ast::Node>} // Ensures YYSTYPE is std::shared_ptr<ast::Node>

// TODO: Define tokens here
%token VOID INT BYTE BOOL AND OR NOT TRUE FALSE RETURN IF ELSE WHILE BREAK CONTINUE SC COMMA LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK ASSIGN ID NUM NUM_B STRING
%token EQ NE LT GT LE GE ADD SUB MUL DIV
%token errorlex // Added for scanner error reporting

// TODO: Define precedence and associativity here
%right ASSIGN
%left  OR
%left  AND
%left  EQ NE
%left  LT GT LE GE
%left  ADD SUB
%left  MUL DIV
%right NOT
%right CAST_PREC      // For (Type)Exp cast operations - Reinstated
%nonassoc NO_ELSE     // For if-statement without an else part - Reinstated
%right ELSE        // For the ELSE keyword (dangling else resolution)


%%

// While reducing the start variable, set the root of the AST
Program:  Funcs { program = $1; }
Funcs: /* empty */ {$$ = std::make_shared<ast::Funcs>();}
        | FuncDecl Funcs {
              std::shared_ptr<ast::Funcs> funcs =  std::dynamic_pointer_cast<ast::Funcs>($2);
              std::shared_ptr<ast::FuncDecl> list = std::dynamic_pointer_cast<ast::FuncDecl>($1);
              funcs->push_front(list);
              $$ = $2;
         }
FuncDecl: RetType ID LPAREN Formals RPAREN LBRACE Statements RBRACE {

        std::shared_ptr<ast::ID> id = std::dynamic_pointer_cast<ast::ID>($2);
        std::shared_ptr<ast::Formals> formals = std::dynamic_pointer_cast<ast::Formals>($4);
        std::shared_ptr<ast::Statements> body = std::dynamic_pointer_cast<ast::Statements>($7);
        $$ = std::make_shared<ast::FuncDecl>(id, std::dynamic_pointer_cast<ast::Type>($1), formals, body);
 }
 
RetType: Type {$$ = $1; }
RetType: VOID { $$ = std::make_shared<ast::PrimitiveType>(ast::BuiltInType::VOID); }
Formals:  { 
        $$ = std::make_shared<ast::Formals>();
                }
        | FormalsList {
                $$ = $1;
         }

FormalsList: FormalDecl { $$ = std::make_shared<ast::Formals>(std::dynamic_pointer_cast<ast::Formal>($1));}
        | FormalDecl COMMA FormalsList {
              std::shared_ptr<ast::Formal> formal =  std::dynamic_pointer_cast<ast::Formal>($1);
              std::shared_ptr<ast::Formals> list = std::dynamic_pointer_cast<ast::Formals>($3);
              list->push_front(formal);
              $$ = $3;
         }
FormalDecl: Type ID {
        std::shared_ptr<ast::Type> type = std::dynamic_pointer_cast<ast::Type>($1);
        std::shared_ptr<ast::ID> id =std::dynamic_pointer_cast<ast::ID>($2);
        $$ = std::make_shared<ast::Formal>(id,type);
        }
Statements: Statement {
        std::shared_ptr<ast::Statement> value = std::dynamic_pointer_cast<ast::Statement>($1);
        $$ = std::make_shared<ast::Statements>(value);
        }
        | Statements Statement { 
                std::shared_ptr<ast::Statements> statements = std::dynamic_pointer_cast<ast::Statements>($1);
                statements->push_back(std::dynamic_pointer_cast<ast::Statement>($2));
                $$ = $1;
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
                $$ = std::make_shared<ast::VarDecl>(id, type, std::dynamic_pointer_cast<ast::Exp>($4));
         }
        | ID ASSIGN Exp SC {
                std::shared_ptr<ast::ID> id = std::dynamic_pointer_cast<ast::ID>($1);
                std::shared_ptr<ast::Exp> exp = std::dynamic_pointer_cast<ast::Exp>($3);
                $$ = std::make_shared<ast::Assign>(id,exp);
         }
        | ID LBRACK Exp RBRACK ASSIGN Exp SC { 
                std::shared_ptr<ast::ID> id = std::dynamic_pointer_cast<ast::ID>($1);
                std::shared_ptr<ast::Exp> index = std::dynamic_pointer_cast<ast::Exp>($3);
                std::shared_ptr<ast::Exp> value = std::dynamic_pointer_cast<ast::Exp>($6);
                $$ = std::make_shared<ast::ArrayAssign>(id,value,index);
        }
        | Type ID LBRACK Exp RBRACK SC {
                std::shared_ptr<ast::PrimitiveType> base_type = std::dynamic_pointer_cast<ast::PrimitiveType>($1);
                std::shared_ptr<ast::ID> id = std::dynamic_pointer_cast<ast::ID>($2);
                $$ = std::make_shared<ast::VarDecl>(
                    id,
                    std::make_shared<ast::ArrayType>(base_type->type, std::dynamic_pointer_cast<ast::Exp>($4))
                );
        }
        | Call SC {$$ = $1;}
        | RETURN SC {$$ = std::make_shared<ast::Return>();}
        | RETURN Exp SC {$$ = std::make_shared<ast::Return>(std::dynamic_pointer_cast<ast::Exp>($2));}
        | IF LPAREN Exp RPAREN Statement %prec NO_ELSE {
                std::shared_ptr<ast::Exp> expression = std::dynamic_pointer_cast<ast::Exp>($3);
                std::shared_ptr<ast::Statement> statement = std::dynamic_pointer_cast<ast::Statement>($5);
                $$ = std::make_shared<ast::If>(expression,statement);
        }
        | IF LPAREN Exp RPAREN Statement ELSE Statement {
                std::shared_ptr<ast::Exp> expression = std::dynamic_pointer_cast<ast::Exp>($3);
                std::shared_ptr<ast::Statement> statement = std::dynamic_pointer_cast<ast::Statement>($5);
                std::shared_ptr<ast::Statement> else_statement = std::dynamic_pointer_cast<ast::Statement>($7);
                $$ = std::make_shared<ast::If>(expression,statement,else_statement);
         }
        | WHILE LPAREN Exp RPAREN Statement {
                std::shared_ptr<ast::Exp> expression =std::dynamic_pointer_cast<ast::Exp>($3);
                std::shared_ptr<ast::Statement> statement = std::dynamic_pointer_cast<ast::Statement>($5);
                $$ = std::make_shared<ast::While>(expression,statement);
         }
        | BREAK SC {$$ =   std::make_shared<ast::Break>();}
        | CONTINUE SC {$$ = std::make_shared<ast::Continue>();}

Call: ID LPAREN ExpList RPAREN {
        std::shared_ptr<ast::ExpList> args = std::dynamic_pointer_cast<ast::ExpList>($3);
        std::shared_ptr<ast::ID> func_id = std::dynamic_pointer_cast<ast::ID>($1);
        $$ =  std::make_shared<ast::Call>(func_id,args);
 }
        | ID LPAREN RPAREN {
        std::shared_ptr<ast::ID> func_id = std::dynamic_pointer_cast<ast::ID>($1);
        $$ = std::make_shared<ast::Call>(func_id);
         }

ExpList: Exp {
            auto new_list = std::make_shared<ast::ExpList>();
            new_list->push_front(std::dynamic_pointer_cast<ast::Exp>($1));
            $$ = new_list;
         }
        | Exp COMMA ExpList { 
                std::shared_ptr<ast::ExpList> e_list = std::dynamic_pointer_cast<ast::ExpList>($3);
                e_list->push_front(std::dynamic_pointer_cast<ast::Exp>($1)); 
                $$ = e_list;
        }

Type: INT {$$ = std::make_shared<ast::PrimitiveType>(ast::BuiltInType::INT);}
    | BYTE {$$ = std::make_shared<ast::PrimitiveType>(ast::BuiltInType::BYTE);}
    | BOOL {$$ = std::make_shared<ast::PrimitiveType>(ast::BuiltInType::BOOL);}

Exp: LPAREN Exp RPAREN {$$ = std::dynamic_pointer_cast<ast::Exp>($2);}
    | ID LBRACK Exp RBRACK {$$ = std::make_shared<ast::ArrayDereference>(std::dynamic_pointer_cast<ast::ID>($1),std::dynamic_pointer_cast<ast::Exp>($3));}
    | Exp DIV Exp {$$ = std::make_shared<ast::BinOp>(std::dynamic_pointer_cast<ast::Exp>($1),std::dynamic_pointer_cast<ast::Exp>($3),ast::BinOpType::DIV);}
    | Exp MUL Exp {$$ = std::make_shared<ast::BinOp>(std::dynamic_pointer_cast<ast::Exp>($1),std::dynamic_pointer_cast<ast::Exp>($3),ast::BinOpType::MUL);}
    | Exp SUB Exp {$$ = std::make_shared<ast::BinOp>(std::dynamic_pointer_cast<ast::Exp>($1),std::dynamic_pointer_cast<ast::Exp>($3),ast::BinOpType::SUB);}
    | Exp ADD Exp {$$ = std::make_shared<ast::BinOp>(std::dynamic_pointer_cast<ast::Exp>($1),std::dynamic_pointer_cast<ast::Exp>($3),ast::BinOpType::ADD);}
    | ID {$$ = $1;}
    | Call {$$ = $1;}
    | NUM {$$ = $1;}
    | NUM_B {$$ = $1;}
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
    | LPAREN Type RPAREN Exp %prec CAST_PREC {$$ = std::make_shared<ast::Cast>(std::dynamic_pointer_cast<ast::Exp>($4),std::dynamic_pointer_cast<ast::PrimitiveType>($2)); }


;

// TODO: Define grammar here

%%

// TODO: Place any additional code here
void yyerror(const char* s) {
        output::errorSyn(yylineno);
        exit(0);
}