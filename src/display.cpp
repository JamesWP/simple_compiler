#include "display.h"
#include "ast.h"
#include "textbox.hh"

std::ostream& printExpressionTree(std::ostream& out, const expression& e)
{
  auto creator = [](const expression &e) {
    std::ostringstream ss;
    switch(e.type){
    case ex_type::binop: {
      if (e.otype == op_type::assign) {
        ss << e.params.begin()->ident << ' ' << '=';
      }
      else {
        ss << e.type;
        ss << '/';
        ss << e.otype;
      }
    } break;
    case ex_type::number: {
      ss << e.number_value;
    } break;
    case ex_type::ident: {
      ss << e.ident;
    } break;
    default:
      ss << e.type;
    }
    return ss.str();
  };
  auto counter =
      [](const expression &e) -> std::pair<decltype(e.params)::const_iterator,
                                           decltype(e.params)::const_iterator> {
    if (e.type == ex_type::binop && e.otype == op_type::assign) {
      return {++e.params.begin(), e.params.end()};
    }
    return {e.params.begin(), e.params.end()};
  };

  auto one_liner = [](const expression &e) { 
    switch (e.type) {
    case ex_type::number:
    case ex_type::ident:
    case ex_type::ret:
    case ex_type::binop:
      return true;
    default:
      return false;
    }
 };
  auto simple = [](const expression &e) {
    switch (e.type) {
    case ex_type::number:
    case ex_type::ident:
    case ex_type::binop:
      return true;
    default:
      return false;
    }
  };
  auto sep_first = [](const expression &e) {
    switch (e.type) {
    case ex_type::block:
    case ex_type::cond:
      return true;
    default:
      return false;
    }
  };

  textbox t = create_tree_graph<decltype(e.params)::const_iterator>(
      e, 80, creator, counter, one_liner, simple, sep_first);

  out << t.to_string();
 
  return out;
}
