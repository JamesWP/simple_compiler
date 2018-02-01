// vim: set syntax=cpp:
#ifndef SC_AST
#define SC_AST

#include <iostream>
#include <list>
#include <ostream>
#include <string>
#include <set>
#include <sstream>
#include <string>
#include <unordered_map>
#include <unordered_set>

enum class ex_type { number, ident, binop, define, block, ret, cond, undefined };

inline std::ostream &operator<<(std::ostream &out, ex_type t)
{
  switch (t) {
  case ex_type::number:
    return (out << "NUMR");
  case ex_type::ident:
    return (out << "IDT");
  case ex_type::binop:
    return (out << "BOP");
  case ex_type::define:
    return (out << "DEF");
  case ex_type::block:
    return (out << "BLK");
  case ex_type::ret:
    return (out << "RET");
  case ex_type::cond:
    return (out << "CND");
  case ex_type::undefined:;
  }
  return (out << "UNKNOWN");
}

enum class op_type { add, minus, multiply, divide, assign, undefined };

inline std::ostream &operator<<(std::ostream &out, op_type t)
{
  switch (t) {
  case op_type::add:
    return (out << "ADD");
  case op_type::minus:
    return (out << "MIN");
  case op_type::multiply:
    return (out << "MUL");
  case op_type::divide:
    return (out << "DIV");
  case op_type::assign:
    return (out << "ASN");
  case op_type::undefined:;
  }
  return (out << "UNKNOWN");
}

using expr_list = std::list<struct expression>;

struct expression {
  ex_type type;      // the type of expression
  op_type otype;     // the type of the binary exression
  int number_value;  // used to store the literal value of the expr
  std::string ident; // used to store the name of the identifier
  expr_list params;  // used to store sub expressions

  expression(int number) : type(ex_type::number), number_value(number) {}

  expression(std::string &&_ident)
      : type(ex_type::ident), ident(std::move(_ident))
  {
  }

  expression(expression &&left, expression &&right, op_type ot)
      : type(ex_type::binop), otype(ot)
  {
    addParam(std::move(left));
    addParam(std::move(right));
  }

  expression(std::string &&_ident, expression &&val)
      : type(ex_type::define), ident(std::move(_ident))
  {
    addParam(std::move(val));
  }

  expression(ex_type t, expression&& e)
  : type(t)
  {
      addParam(std::move(e));
  }

  expression(ex_type t, expression&& e1, expression&& e2)
  : type(t)
  {
      addParam(std::move(e1));
      addParam(std::move(e2));
  }

  expression(ex_type t, expression&& e1, expression&& e2, expression&& e3)
  : type(t)
  {
      addParam(std::move(e1));
      addParam(std::move(e2));
      addParam(std::move(e3));
  }

  expression(expr_list &&exprs) : type(ex_type::block), params(std::move(exprs))
  {
  }

  expression() : type(ex_type::undefined) {}

  expression(const expression &o) = delete;

  expression(expression &&o) { *this = std::move(o); }

  expression &operator=(expression &&right)
  {
    type = right.type;
    otype = right.otype;
    ident = std::move(right.ident);
    number_value = right.number_value;
    params = std::move(right.params);
    return *this;
  }

  void addParam(expression &&expr) { params.push_back(std::move(expr)); }

  template <typename V>
  void visit(V &v) const
  {
    v(*this);
    for (auto &ex : params)
      ex.visit(v);
  }

  // get all the variable names, defined inside here
  std::set<std::string> varSet() const
  {
    std::set<std::string> vars;
    auto add = [&vars](const expression &e) {
      if (e.type == ex_type::define)
        vars.insert(e.ident);
    };
    visit(add);
    return vars;
  }
};

inline std::ostream &print(std::ostream &out, const expression &e, int indent = 1)
{
  out << '(' << e.type << ' ';
  switch (e.type) {
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
    if (indent > 0)
      out << '\n';
    for (auto ex = e.params.begin(); ex != e.params.end(); ex++) {
      for (int i = 0; i < indent; i++)
        out << ' ';
      print(out, *ex, indent + 1);
      out << '\n';
    }
    if (indent > 0) {
      for (int i = 0; i < indent - 1; i++)
        out << ' ';
    }
    break;
  case ex_type::ret:
    out << " return: ";
    print(out, *e.params.begin());
    break;
  case ex_type::cond: {
    auto cond = e.params.begin();
    auto trExp = ++e.params.begin();
    auto faExp = ++++e.params.begin();

    out << "IF ";
    print(out, *cond, indent+1);

    out << '\n';
    if (indent > 0) {
      for (int i = 0; i < indent; i++)
        out << ' ';
    }

    out << " TRUE:  ";
    print(out, *trExp, indent+1);

    out << '\n';
    if (indent > 0) {
      for (int i = 0; i < indent; i++)
        out << ' ';
    }
  
    if(faExp != e.params.end()){
        out << " FALSE: ";
        print(out, *faExp);
    }
    out << " ENDIF";
  } break;
  default:
    out << "type: " << e.type << " has no printer";
  }

  return (out << ')');
}

inline std::ostream &operator<<(std::ostream &out, const expression &e)
{
  return print(out, e);
}

#endif
