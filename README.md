# simple_compiler [![CircleCI](https://circleci.com/gh/JamesWP/simple_compiler.svg?style=svg)](https://circleci.com/gh/JamesWP/simple_compiler)

## requirements

- [bison](https://www.gnu.org/software/bison/) - parser generator
- [re2c](http://re2c.org/) - lexer generator
- [cmake](https://cmake.org/) - build

## building
```bash
$ mkdir bld
$ cd bld
$ cmake -GNinja ..
$ cmake --build .
```
