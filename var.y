%skeleton "lalr1.cc"
%define parser_class_name {calc_parser}
%define api.token.constructor
%define api.value.type variant
%define parse.assert
%define parse.error verbose
%locations

%code requires
{
#include <list>
#include <iostream>
#include <ostream>
#include <string>
#include <unordered_set>

enum class ex_type { number, ident, binop, define, block, undefined };

std::ostream& operator<<(std::ostream& out, ex_type t)
{
    switch(t){
        case ex_type::number: return (out << "NUMBER");
        case ex_type::ident:  return (out << "IDENT");
        case ex_type::binop:  return (out << "BINOP");
        case ex_type::define: return (out << "DEFINE");
        case ex_type::block:  return (out << "BLOCK");
        case ex_type::undefined:;
    }
    return (out << "UNKNOWN");
}

enum class op_type { add, minus, multiply, divide, assign, undefined };

std::ostream& operator<<(std::ostream& out, op_type t)
{
    switch(t){
        case op_type::add:         return (out << "ADD");
        case op_type::minus:       return (out << "MINUS");
        case op_type::multiply:    return (out << "MULTIPLY");
        case op_type::divide:      return (out << "DIVIDE");
        case op_type::assign:      return (out << "ASSIGN");
        case op_type::undefined:;
    }
    return (out << "UNKNOWN");
}

using expr_list = std::list<struct expression>;

struct expression
{
    ex_type   type;           // the type of expression
    op_type   otype;          // the type of the binary exression
    int       number_value;   // used to store the literal value of the expr
    std::string ident;        // used to store the name of the identifier
    expr_list params;         // used to store sub expressions

    expression(int number)
    : type(ex_type::number)
    , number_value(number)
    {
    }

    expression(std::string&& _ident)
    : type(ex_type::ident)
    , ident(std::move(_ident))
    {
    }

    expression(expression&& left, expression&& right, op_type ot)
    : type(ex_type::binop)
    , otype(ot)
    {
        addParam(std::move(left));
        addParam(std::move(right));
    }

    expression(std::string&& _ident, expression&& val)
    : type(ex_type::define)
    , ident(std::move(_ident))
    {
        addParam(std::move(val));
    }

    expression(ex_type t, expression&& e)
    : type(t)
    {
        addParam(std::move(e));
    }

    expression(expr_list&& exprs)
    : type(ex_type::block)
    , params(std::move(exprs))
    {
    }

    expression()
    : type(ex_type::undefined)
    {}

    expression(const expression& o) = delete;

    expression(expression&& o)
    {
        *this = std::move(o);
    }

    expression& operator=(expression&& right)
    {
        type = right.type;
        otype = right.otype;
        ident = std::move(right.ident);
        number_value = right.number_value;
        params = std::move(right.params);
        return *this;
    }

    void addParam(expression&& expr) { params.push_back(std::move(expr)); }
};

std::ostream& print(std::ostream& out, const expression& e, int indent = 1)
{
    out << "type: " << e.type << ' ' << '(';
    switch(e.type) {
        case ex_type::number:
          out << " val: " << e.number_value;
          break;
        case ex_type::ident:
          out << " ident: " << e.ident;
          break;
        case ex_type::define:
          out << " name: " << e.ident << " as: ";
          print(out, *e.params.begin());
          break;
        case ex_type::binop:
          print(out, *e.params.begin());
          out << ' ' << e.otype << ' ';
          print(out, *(++e.params.begin()));
          break;
        case ex_type::block:
          if(indent > 0) out << '\n';
          for (auto ex = e.params.begin(); ex != e.params.end(); ex++) {
              for (int i = 0; i < indent; i++)
                  out << ' ';
              print(out, *ex, indent+1);
          }
          if (indent > 0) {
              out << '\n';
              for (int i = 0; i < indent -1; i++)
                  out << ' ';
          }
          break;
        default:
          out << "type: " << e.type << " has no printer";
    }

    return (out << ')');
}

std::ostream& operator<<(std::ostream& out, const expression& e) { return print(out, e); }

struct lexcontext;

} // %code requires

%param { lexcontext& ctx }

%code
{

struct symbol_table
{
    std::unordered_set<std::string> defined;

    bool isDefined(const std::string& var) const
    {
        return defined.find(var) != defined.end();
    }

    void define(const std::string& var)
    {
        defined.insert(var);
    }
};

struct lexcontext
{
    const char* cursor;
    yy::location loc;

    symbol_table sym;

    template<typename Parser>
    void useVar(const std::string& var, Parser& p)
    {
        if(sym.isDefined(var)) return;
        std::string ermsg="variable used but not defined: ";
        ermsg += var;
        ermsg += ". assuming defined here";
        p.error(loc, ermsg.c_str());
        sym.define(var);
    }

    template<typename Parser>
    void defineVar(const std::string& var, Parser& p)
    {
        if(sym.isDefined(var)) {
            std::string ermsg = "variable already defined: ";
            ermsg += var;
            p.error(loc, ermsg.c_str());
            return;
        }
        sym.define(var);
    }
};

namespace yy { calc_parser::symbol_type yylex(lexcontext& ctx); }

} // %code

%token END 0
%token VAR "var"
%token NUMBERCONST
%token IDENTIFIER

%left '+' '-'
%left '*' '/'
%left '('
%left '='

%type<int>            NUMBERCONST
%type<std::string>    IDENTIFIER

%type<expression>     expr stmt com_stmt
%type<expr_list>      stmts
%%

go: stmt                     { std::cout << $1 << '\n'; }

stmts:
    error                    { $$.push_back(-1); }
|   stmts error              { $$ = std::move($1); }
|   stmts stmt ';'           { $$.push_back(std::move($2)); }
|   ';'                      { }
|   %empty                   { }
;

stmt:
    expr error               { $$ = -1; }
|   com_stmt stmt '}'        { }
|   expr                     { $$ = std::move($1); }
|   "var" IDENTIFIER '=' expr
                             { ctx.defineVar($2, *this); $$ = std::move(expression(std::move($2), std::move($4))); }
|   "var" IDENTIFIER         { ctx.defineVar($2, *this); $$ = std::move(expression(std::move($2), std::move(expression()))); }
;

com_stmt:
    com_stmt stmt
|   '{'

expr:
    error                    { $$ = -1; }
// Literals
|   NUMBERCONST              { $$ = $1; }
|   IDENTIFIER               { ctx.useVar($1, *this); $$ = std::move($1);  }
// Binary operations
|   expr '+' expr            { $$ = std::move(expression(std::move($1), std::move($3), op_type::add)); }
|   expr '-' expr            { $$ = std::move(expression(std::move($1), std::move($3), op_type::minus)); }
|   expr '*' expr            { $$ = std::move(expression(std::move($1), std::move($3), op_type::multiply)); }
|   expr '/' expr            { $$ = std::move(expression(std::move($1), std::move($3), op_type::divide)); }
|   expr '=' expr            { $$ = std::move(expression(std::move($1), std::move($3), op_type::assign)); }
// Brackets
|   '(' expr ')'             { $$ = std::move($2); }
;

%%

yy::calc_parser::symbol_type yy::yylex(lexcontext& ctx)
{
    const char* anchor = ctx.cursor;
    ctx.loc.step();
%{ // begin re2c
re2c:yyfill:enable   = 0;
re2c:define:YYCTYPE  = "char";
re2c:define:YYCURSOR = "ctx.cursor";

// Keywords
"var"
{
    ctx.loc.columns(ctx.cursor - anchor);
    return calc_parser::make_VAR(ctx.loc);
}

// Literals
[0-9]+
{
    ctx.loc.columns(ctx.cursor - anchor);
    return calc_parser::make_NUMBERCONST(
        std::stoi(std::string(anchor, ctx.cursor)), ctx.loc);
}
// Identifier
[a-zA-Z_] [a-zA-Z_0-9]*
{
    ctx.loc.columns(ctx.cursor - anchor);
    return calc_parser::make_IDENTIFIER(
        std::string(anchor, ctx.cursor), ctx.loc);
}
// Whitespace
"\000"
{
    ctx.loc.columns(ctx.cursor - anchor);
    return calc_parser::make_END(ctx.loc);
}
"\r\n" | [\r\n]
{
    ctx.loc.lines();
    return yylex(ctx);
}
"//" [^\r\n]*
{
    return yylex(ctx);
}
[\t\v\b\f ]
{
    ctx.loc.columns();
    return yylex(ctx);
}
// Single char symbols
.
{
    ctx.loc.columns(ctx.cursor - anchor);
    return calc_parser::symbol_type(
        calc_parser::token_type(ctx.cursor[-1] & 0xFF), ctx.loc);
}

%} // emd re2c
}

void yy::calc_parser::error(const location_type& l, const std::string& message)
{
    std::cerr << (l.begin.filename ? l.begin.filename->c_str()
                                   : "(not specified)");
    std::cerr << ":" << l.begin.line << ' ' << l.begin.column << '-'
              << l.end.column << ":" << message << '\n';
}

#include <fstream>

int main(int argc, char* argv[])
{
    if(argc != 2) return 1;
    std::string infile(argv[1]);
    std::ifstream input(infile);
    if(!input)    return 2;
    std::string buffer(std::istreambuf_iterator<char>(input), {});

    std::cout << "input:\n";
    std::cout << buffer << "\n";

    lexcontext ctx;

    ctx.cursor = buffer.c_str();
    ctx.loc.begin.filename = &infile;
    ctx.loc.end.filename   = &infile;

    yy::calc_parser parser(ctx);

    parser.parse();
}

// vim: set syntax=cpp:
