cc = gcc
programs = eat_mem eat_cpu
includes = $(shell find ./ -name "*.h")
src = $(shell find ./ -name "*.c")

all: $(programs)
eat_mem: eat_mem.o
	$(cc) -o eat_mem -pthread eat_mem.o
eat_cpu: eat_cpu.o
	$(cc) -o eat_cpu -pthread eat_cpu.o
%.o: %.c $(deps)
	$(cc) -g -c $< -o $@

.PHONY:clean install
clean:
	rm -rf *.o $(programs)
install:
	cp -rp $(programs) ../bin/
