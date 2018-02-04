#include "frontend.h"
#include "codegen.h"
#include "display.h"

#include <fstream>
#include <cstring>
#include <algorithm>

const char *getOption(int argc, const char *argv[], const char *option,
                      const char *def)
{
  for (const char **arg = argv; arg != argv + argc && *arg != nullptr; arg++) {
    const char* argVal = *arg;
    if (argVal[0] == '\0') continue;
    if (argVal[0] != '-') continue;
    if (std::strcmp(argVal+1, option) == 0){
      return *(arg+1);
    }
    arg++;
  }
  return def;
}

const char *getNonNamedArg(int argc, const char*argv[])
{
  for (const char **arg = argv; arg != argv + argc && *arg != nullptr; arg++) {
    const char* argVal = *arg;
    if (argVal[0] == '\0') continue;
    if (argVal[0] == '-') { arg++; continue; }
    return *arg;
  }

  return nullptr;
}

int main(int argc, char* argv[])
{
  
  argc--;
  argv++;

  const char *inFileName =
      getNonNamedArg(argc, const_cast<const char **>(argv));

  if (inFileName == nullptr) return 1;

  std::string infile(inFileName);
  std::ifstream input(infile);
  if (!input)
    return 2;

  const char *outFileName =
      getOption(argc, const_cast<const char **>(argv), "o", "-");

  const char *verbStr =
      getOption(argc, const_cast<const char **>(argv), "v", "0");
  const int verb = std::atoi(verbStr);

  expression e = parse(input);
  if (verb > 0) {
    printExpressionTree(std::cout, e);
  }

  Stream s(e);
  if (std::strcmp(outFileName, "-") == 0) {
    std::cout << s.str();
  }
  else {
    std::ofstream out{outFileName};
    out << s.str();
  }
}

