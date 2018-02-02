#include "frontend.h"
#include "codegen.h"
#include "display.h"

#include <fstream>

int main(int argc, char* argv[])
{
    if(argc < 2) return 1;
    std::string infile(argv[1]);
    std::ifstream input(infile);
    if(!input)    return 2;

    expression e = parse(input);
    if (argc > 1) {
      printExpressionTree(std::cout, e);
    }

    //Stream s(e);
    //std::cout << s.str();
}
