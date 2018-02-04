#ifndef CODEGEN_x86
#define CODEGEN_x86

#include <iostream>
#include <sstream>

class StreamL1 {
  std::ostringstream out;

public:
  StreamL1() {}
  void assignAcc(const int v) { out << "  mov rax, " << v << '\n'; }

  void assignAccMem(int o)
  {
    out << "  mov rax, DWORD PTR [rbp-" << o * 4 << "] " << '\n';
  }

  void push() { out << "  pushq rax\n"; }

  void popTmp() { out << "  popq rdx\n"; }

  void saveTmp() { out << "  mov rdx, rax\n"; }

  void setupStack(int vars) 
  { 
    out << "  push rbp\n";
    out << "  mov rbp, rsp\n"; 
    out << "  sub rsp, " << vars * 4 << '\n';
  }

  void restoreStack() 
  {
    out << "  mov rbp, rsp\n"; 
    out << "  pop rbp\n";
  }

  void storeMem(int o)
  {
    out << "  mov DWORD PTR [rbp-" << o * 4 << "], rax" << '\n';
  }

  void addTmp() { out << "  add rax, rdx\n"; }
  void minusTmp() { out << "  sub rax, rdx\n"; }
  void multiplyTmp() { out << "  imul rax, rdx\n"; }
  void divideTmp() { out << "  idiv rax, rdx\n"; }
  void swap() { out << "  xchg rax, rdx\n"; }
  void ret() { out << "  ret" << '\n'; }

  void jumpIfZero(const std::string &label)
  {
    out << "  cmp rax, 0\n";
    out << "  jz " << label << '\n';
  }
  void jump(const std::string &label) { out << "  jmp " << label << '\n'; }
  void label(const std::string &label) { out << label << ':' << '\n'; }

  void filePreamble() { out << "  .intel_syntax noprefix\n"; }
  void funcitonPreamble(const char *fname)
  {
    out << '\n';
    out << "  .globl " << fname << '\n';
    out << fname << ':' << '\n';
  }

  const std::string str() { return out.str(); }
};

#endif
