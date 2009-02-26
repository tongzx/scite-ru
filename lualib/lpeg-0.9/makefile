LUADIR = ../../src/scite/lua/include
LUALIB = -L ../lib/ -lscite
COPT = -O2 -DNDEBUG
CFLAGS = -s -ansi -I$(LUADIR) -shared -o lpeg.dll $(LUALIB)
CC = gcc

all: dll

dll: lpeg.c
	$(CC) $(COPT) lpeg.c $(CFLAGS)

test: test.lua re.lua lpeg.so
	test.lua
