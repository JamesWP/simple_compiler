from ubuntu:16.04

RUN apt-get update -q && apt-get install -y bison re2c g++ gcc binutils make

