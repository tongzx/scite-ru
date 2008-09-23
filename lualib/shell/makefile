LIBS= -lscite -lshlwapi -lstdc++
LIBDIR= -L ../lib/

OUTFILE= shell.dll

LUA= ../../src/scite/lua/include

CFLAGS= -s -I$(LUA)

CC= g++

$(OUTFILE): resfile.o
	$(CC) $(CFLAGS) -shared -o $(OUTFILE) shell.cpp resfile.o $(LIBDIR) $(LIBS)

resfile.o: shell.rc
	windres -o resfile.o shell.rc

all: $(OUTFILE)

clean:
	-del *.o

