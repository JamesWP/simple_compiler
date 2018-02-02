%skeleton "lalr1.cc"
%define parser_class_name {calc_parser}
%define api.token.constructor
%define api.value.type variant
%define parse.assert
%define parse.error verbose
%locations

%code requires
{
#include "ast.h"
#include "codegen.h"
#include "frontend.h"

struct lexcontext;

} // %code requires

%param { lexcontext& ctx }

%code
{

struct symbol_table
{
    using scope_map = std::unordered_set<std::string>;
    std::list<scope_map> defined;

    // isDefined in this or any other visible scope
    bool isDefined(const std::string& var) const
    {
        assert(!defined.empty());

        for(const auto& sc : defined) {
          if(sc.find(var) != sc.end()){
            return true;
          }
        }

        return false;
    }

    void define(const std::string& var)
    {
        assert(!defined.empty());
        defined.begin()->insert(var);
    }

    void newScope()           { defined.push_front({}); }
    void closeScope()         { defined.pop_front(); }
    int thisScopeSize() const { return defined.begin()->size(); }
};

struct lexcontext
{
    expression result;

    int verb = 0;
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

    void newScope() { sym.newScope(); }
    void closeScope() { sym.closeScope(); }
};

namespace yy { calc_parser::symbol_type yylex(lexcontext& ctx); }

} // %code

%token END 0
%token VAR "var" RETURN "return" IF "if" ELSE "else"
%token NUMBERCONST
%token IDENTIFIER

%left '='
%left '+' '-'
%left '*' '/'
%left '('

%right ')'
%right ELSE 

%type<int>            NUMBERCONST
%type<std::string>    IDENTIFIER

%type<expression>     expr stmt
%type<expr_list>      com_stmt

%%

go: { ctx.newScope(); } stmt { ctx.closeScope();
                               ctx.result = std::move($2); }

stmt:
    expr error               { $$ = -1; }
|   com_stmt '}'             { $$ = std::move($1); 
                               ctx.closeScope(); }
|   expr ';'                 { $$ = std::move($1); }
|   "var" IDENTIFIER '=' expr ';'
                             { ctx.defineVar($2, *this); 
                               $$ = expression(std::move($2), std::move($4)); }
|   "var" IDENTIFIER ';'     { ctx.defineVar($2, *this); 
                               $$ = expression(std::move($2), expression()); }
|   "if" '(' expr ')' stmt   { $$ = expression(ex_type::cond, std::move($3), std::move($5)); }
|   "if" '(' expr ')' stmt "else" stmt 
                             { $$ = expression(ex_type::cond, std::move($3), std::move($5), std::move($7)); }
|   "return" expr ';'        { $$ = expression(ex_type::ret, std::move($2)); }
;

com_stmt:
    com_stmt stmt            { $$ = std::move($1); $$.push_back(std::move($2)); }
|   '{'                      { ctx.newScope(); 
                               $$ = expr_list(); } 

expr:
    NUMBERCONST              { $$ = $1; }
|   IDENTIFIER               { ctx.useVar($1, *this); 
                               $$ = std::move($1);  }
|   expr '+' expr            { $$ = expression(std::move($1), std::move($3), op_type::add); }
|   expr '-' expr            { $$ = expression(std::move($1), std::move($3), op_type::minus); }
|   expr '*' expr            { $$ = expression(std::move($1), std::move($3), op_type::multiply); }
|   expr '/' expr            { $$ = expression(std::move($1), std::move($3), op_type::divide); }
|   expr '=' expr            { $$ = expression(std::move($1), std::move($3), op_type::assign); }
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
"return"
{
    ctx.loc.columns(ctx.cursor - anchor);
    return calc_parser::make_RETURN(ctx.loc);
}
"if"
{
    ctx.loc.columns(ctx.cursor - anchor);
    return calc_parser::make_IF(ctx.loc);
}
"else"
{
    ctx.loc.columns(ctx.cursor - anchor);
    return calc_parser::make_ELSE(ctx.loc);
}
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

expression parse(std::istream& input, std::string inputName, int verb)
{
    std::string buffer(std::istreambuf_iterator<char>(input), {});

    lexcontext ctx;

    ctx.verb = verb; 

    if(ctx.verb > 0){
      std::cout << "input:\n";
      std::cout << buffer << "\n";
    }

    ctx.cursor = buffer.c_str();
    ctx.loc.begin.filename = &inputName;
    ctx.loc.end.filename   = &inputName;

    yy::calc_parser parser(ctx);

    parser.parse();

    return std::move(ctx.result);
}

// vim: set syntax=cpp:
