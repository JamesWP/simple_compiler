CXX_FLAGS=-Wall -Wextra -O0 -g -std=c++14 -DYY_NULLPTR=nullptr
BISON_FLAGS=-t --report=all

PROGS:=$(pathsubst %.y,%.prog,$(wildcard *.y))

re2c=re2c

all: $(PROGS)

%.re: %.y ast.hpp
	bison "$<" -o "$@" 
	#make it movable
	sed -i 's/new (yyas_<T> ()) T (t)/new (yyas_<T> ()) T (std\:\:move((T\&)t))/' $@

%.cc: %.re
	$(re2c) "$<" -o "$@"

%.prog: %.cc
	g++ $(CXX_FLAGS) "$<" -o "$@"

clean:
	rm -rf *.re
	rm -rf *.prog
