# This Makefile builds bwlockmod kernel module.  The generated executables are
# placed in the 'exe' directory
#
# Auhtor	: Waqar Ali (wali@ku.edu)

TOP_DIR 	:= $(shell pwd)
MOD_EXE 	:= $(TOP_DIR)/bwlockmod.ko
TEST_SRC	:= $(wildcard $(TOP_DIR)/test/*.c)

KVERSION 	:= $(shell uname -r)
BLDDIR 		:= /lib/modules/$(KVERSION)/build

all: setup module modtest move
	@echo "> Build Complete. Outputs can be seen in exe directory"

setup:
	@mkdir -p exe
	@rm -f exe/*

module:
	@echo "> Building Perf-Kernel Module"
	@make -C $(BLDDIR) M=$(PWD) modules

move:
	@mv $(MOD_EXE) exe/.

modtest: $(TEST_SRC)
	@echo "> Building BWLOCK Test Executable"
	@$(CC) -std=gnu99 -O2 -g $^ -o exe/$@ -lrt
clean:
	@echo "> Executing Clean Target"
	make -C $(BLDDIR) M=$(PWD) clean
	@rm -rf exe
	@echo "> Cleaning Complete"
