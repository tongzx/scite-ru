INCLUDES  = -I../../src/scite/lua/include
LIBS      = -L../lib -lscite
DEFINES   = -DNDEBUG
CFLAGS    = -Os $(DEFINES) $(INCLUDES)
LDFLAGS   = -s -shared

CC        = gcc
RM        = del

SRC       = lpeg.c
TARGET    = lpeg.dll
OBJECTS   = lpeg.o

all: $(TARGET)

$(OBJECTS): $(SRC)
	$(CC) $(CFLAGS) -o $@ -c $<

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $(TARGET) $(OBJECTS) $(LIBS)

clean:
	-$(RM) lpeg.dll
