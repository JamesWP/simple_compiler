#ifndef FRONTEND
#define FRONTEND

#include "ast.h"

#include <iosfwd>
#include <string>

expression parse(std::istream &input, std::string inputName = "-",
                 int verb = 0);

#endif
