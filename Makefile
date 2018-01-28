CXX_FLAGS=-Wall -Wextra -O0 -g -std=c++14 -DYY_NULLPTR=nullptr
BISON_FLAGS=-t --report=all

PROGS:=var.prog
re2c=re2c

all: $(PROGS)

%.re: %.y ast.hpp
	bison "$<" -o "$@" 
	#make it movable
	sed -i 's/new (yyas_<T> ()) T (t)/new (yyas_<T> ()) T (std\:\:move((T\&)t))/' $@

%.cc: %.re
	$(re2c) "$<" -o "$@"

%.prog: %.cc
	$(CXX) $(CXX_FLAGS) "$<" -o "$@"

test: var.prog
	./var.prog example.var.txt | gcc test.m.c -o example -x assembler-with-cpp - && ./example; echo $$?

clean:
	rm -rf *.re
	rm -rf *.prog
	rm -rf *.cc
