# A simple makefile to build the shared library for intercepting CUDA Runtime
# API calls via LD_PRELOAD
#
# Author	: Waqar Ali (wali@ku.edu)

RED   :='\033[0;31m'
GRN   :='\033[0;32m'
NCL   :='\033[0m'

DIR   := ${CURDIR}
C_LIB := $(wildcard lib/*.c)
S_LIB := custom_cuda.so
S_APP := test
CXX   := g++
I_PTH := /usr/local/cuda-9.0/include

all: build
build: $(S_LIB)
	@echo ${GRN}Build Complete!${NCL}

$(S_LIB): $(C_LIB)
	$(CXX) -I$(I_PTH) -shared -fPIC $< -o $@ -ldl

clean:
	rm -f $(S_LIB)
	@echo ${GRN}Cleaned!${NCL}
