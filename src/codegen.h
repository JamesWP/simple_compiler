#ifndef CODEGEN
#define CODEGEN

#include "ast.h"
#include "codegen_x86.h"

#include <cassert>

class Stream {
  StreamL1 out;

public:
  Stream(const expression &e)
  {
    out.filePreamble();
    out.funcitonPreamble("do_thing");
    emit_stack_frame_push(e.varSet());
    emit(e);
    emit_stack_frame_pop();
    emit_return();
  }

  const std::string str() { return out.str(); }

private:
  void emit_constant(int val) { out.assignAcc(val); }
  void emit_load(const std::string &name)
  {
    auto loc = variable_offset_map.find(name);
    assert(loc != variable_offset_map.end());
    out.assignAccMem(loc->second);
  }
  void emit_store(const std::string &name)
  {
    auto loc = variable_offset_map.find(name);
    assert(loc != variable_offset_map.end());
    out.storeMem(loc->second);
  }
  void emit_return() { out.ret(); }

  void emit_swap() { out.swap(); }

  void emit_op(op_type opType)
  {
    // ops are in acc, and tmp
    switch (opType) {
    case op_type::add:
      return out.addTmp();
    case op_type::minus:
      return out.minusTmp();
    case op_type::multiply:
      return out.multiplyTmp();
    case op_type::divide:
      return out.divideTmp();
    default:
      assert(false);
    }
  }

  std::unordered_map<std::string, int> variable_offset_map;
  uint32_t labNo = 0;

  void emit_stack_frame_push(const std::set<std::string> &vars)
  {
    int size = vars.size();
    int offset = 1;
    for (auto &var : vars) {
      variable_offset_map[var] = offset++;
    }
    out.saveFp();
    out.pushn(size);
    out.setupStack();
  }

  void emit_stack_frame_pop()
  {
    out.popn(variable_offset_map.size());
    out.restoreFp();
  }

  std::string getNextLabel(const char* name)
  {
    std::ostringstream lab;
    lab << name;
    lab << labNo++;
    return lab.str();
  }

  void emit_cond_jump(const std::string& label) 
  {
    out.jumpIfZero(label);
  }

  void emit_label(const std::string& label)
  {
    out.label(label);
  }
  
  void emit_jump(const std::string& label)
  {
    out.jump(label);
  }

  void emit(const expression &expr)
  {
    switch (expr.type) {
    case ex_type::number:
      emit_constant(expr.number_value);
      return;
    case ex_type::ident:
      emit_load(expr.ident);
      return;
    case ex_type::binop: {
      if (expr.otype == op_type::assign) {
        auto opIt = expr.params.begin();
        auto &var = *opIt++;

        // can only assign to variables
        assert(var.type == ex_type::ident);

        // do we have an expression for the value?
        if (opIt == expr.params.end() || opIt->type == ex_type::undefined) {
          // nope: just store whatever
        }
        else {
          auto &value = *opIt;
          emit(value);
        }
        emit_store(var.ident);
      }
      else {
        auto opIt = expr.params.begin();
        auto &firstOp = *opIt++;
        auto &secondOp = *opIt;
        emit(firstOp);
        emit_swap();
        emit(secondOp);
        emit_swap();
        emit_op(expr.otype);
      }
    }
      return;
    case ex_type::define:
      emit(*expr.params.begin());
      emit_store(expr.ident);
      return;
    case ex_type::block:
      for (const auto &e : expr.params) {
        emit(e);
      }
      return;
    case ex_type::ret:
      emit(*expr.params.begin());
      emit_stack_frame_pop();
      emit_return();
      return;
    case ex_type::undefined:
      return;
    case ex_type::cond: {
      auto epr = expr.params.begin();
      emit(*epr++);

      auto falseLabel = getNextLabel("false");
      auto endLabel = getNextLabel("end");

      emit_cond_jump(falseLabel);
      emit(*epr++);

      if (epr != expr.params.end()) { // we have a false
        emit_jump(endLabel);
        emit_label(falseLabel);
        emit(*epr);
        emit_label(endLabel);
      }
      else {
        emit_label(falseLabel);
      }
    }
      return;
    default:
      assert(false);
    }
  }
};

#endif
