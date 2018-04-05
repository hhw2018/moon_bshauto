cc = gcc
programs = eat_mem
includes = $(shell find ./ -name "*.h")
src = $(shell find ./ -name "*.c")

all: $(programs)
eat_mem: eat_mem.o
	$(cc) -o eat_mem -pthread eat_mem.o

%.o: %.c $(deps)
	$(cc) -c $< -o $@

.PHONY:clean install
clean:
	rm -rf *.o $(programs)
install:
	cp -rp $(programs) ../bin/
