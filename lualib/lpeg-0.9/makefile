LUADIR = ../../src/scite/lua/include
LUALIB = -L ../lib/ -lscite
COPT = -Os -DNDEBUG
CFLAGS = -s -ansi -I$(LUADIR) -shared -o lpeg.dll $(LUALIB)
CC = gcc

all: dll

dll: lpeg.c
	$(CC) $(COPT) lpeg.c $(CFLAGS)

clean:
	-rm lpeg.dll
