#ifndef CODEGEN_x86
#define CODEGEN_x86

#include <iostream>
#include <sstream>

class StreamL1 {
  std::ostringstream out;

public:
  StreamL1() {}
  void assignAcc(const int v) { out << "  mov eax, " << v << '\n'; }

  void assignAccMem(int o)
  {
    out << "  mov eax, DWORD PTR [rbp-" << o * 4 << "] " << '\n';
  }

  void push() { out << "  push eax\n"; }

  void pop() { out << "  pop eax\n"; }

  void saveTmp() { out << "  mov edx, eax\n"; }

  void saveFp() { out << "  push rbp\n"; }

  void restoreFp() { out << "  pop rbp\n"; }

  void setupStack() { out << "  mov rbp, rsp\n"; }

  void pushn(int n)
  {
    (void)n;
    return;
  }

  void popn(int n)
  {
    (void)n;
    return;
  }

  void storeMem(int o)
  {
    out << "  mov DWORD PTR [rbp-" << o * 4 << "], eax" << '\n';
  }

  void addTmp() { out << "  add eax, edx\n"; }
  void minusTmp() { out << "  sub eax, edx\n"; }
  void multiplyTmp() { out << "  imul eax, edx\n"; }
  void divideTmp() { out << "  idiv eax, edx\n"; }
  void swap() { out << "  xchg eax,edx\n"; }
  void ret() { out << "  ret" << '\n'; }

  void jumpIfZero(const std::string &label)
  {
    out << "  cmp eax, 0\n";
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
