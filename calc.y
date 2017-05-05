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

enum class ex_type { number, binop, undefined };

std::ostream& operator<<(std::ostream& out, ex_type t)
{
    switch(t){
        case ex_type::number: return (out << "NUMBER");
        case ex_type::binop:  return (out << "BINOP");
        case ex_type::undefined:;
    }
    return (out << "UNKNOWN");
}

enum class op_type { add, minus, multiply, divide, undefined };

std::ostream& operator<<(std::ostream& out, op_type t)
{
    switch(t){
        case op_type::add:         return (out << "ADD");
        case op_type::minus:       return (out << "MINUS");
        case op_type::multiply:    return (out << "MULTIPLY");
        case op_type::divide:      return (out << "DIVIDE");
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
    expr_list params;         // used to store sub expressions

    expression(int number)
    : type(ex_type::number)
    , number_value(number)
    {
    }

    expression(expression&& left, expression &&right, op_type ot)
    : type(ex_type::binop), otype(ot)
    {
        addParam(std::move(left));
        addParam(std::move(right));
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
        number_value = right.number_value;
        params = std::move(right.params);
        return *this;
    }

    void addParam(expression&& expr){ params.push_back(std::move(expr)); }
};

std::ostream& operator<<(std::ostream& out, const expression& e)
{
    out << "type: " << e.type;
    switch(e.type) {
        case ex_type::number:
          return (out << " val: " << e.number_value);
        case ex_type::binop:
          return (out << '(' << *e.params.begin() << ' ' << e.otype << ' '
                      << *(++e.params.begin())
                      << ')');
        default:;
    }

    return (out << "type: " << e.type << " has no printer");
}

struct lexcontext;

} // %code requires

%param { lexcontext& ctx }

%code
{

struct lexcontext
{
    const char* cursor;
    yy::location loc;
};

namespace yy { calc_parser::symbol_type yylex(lexcontext& ctx); }

} // %code

%token END 0
%token NUMBERCONST

%left '+' '-'
%left '*' '/'
%left '('


%type<int>        NUMBERCONST
%type<expression> expr

%%

maincalc:
    maincalc expr            { std::cout << $2 << "\n"; }
|   %empty
;

expr:
    error                    { $$ = -1; }
// Literals
|   NUMBERCONST              { $$ = $1; }
// Binary operations
|   expr '+' expr            { $$ = std::move(expression(std::move($1), std::move($3), op_type::add)); }
|   expr '-' expr            { $$ = std::move(expression(std::move($1), std::move($3), op_type::minus)); }
|   expr '*' expr            { $$ = std::move(expression(std::move($1), std::move($3), op_type::multiply)); }
|   expr '/' expr            { $$ = std::move(expression(std::move($1), std::move($3), op_type::divide)); }
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

// Literals
[0-9]+
{
    ctx.loc.columns(ctx.cursor - anchor);
    return calc_parser::make_NUMBERCONST(
        std::stoi(std::string(anchor, ctx.cursor)), ctx.loc);
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
