#include "frontend.h"
#include <fstream>

int main(int argc, char* argv[])
{
    if(argc < 2) return 1;
    std::string infile(argv[1]);
    std::ifstream input(infile);
    if(!input)    return 2;

    parse(input);
}
