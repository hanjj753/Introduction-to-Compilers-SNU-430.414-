CC = cc
LEX = flex
CFLAGS = -std=c11 -Wall -Wextra -Wpedantic -g
CPPFLAGS =
LDFLAGS =
LDLIBS =
# Add scanner/table helper objects to the corresponding list if you add files.
SCANNER_OBJECTS = lex.yy.o
HASH_OBJECTS = hash.o
OBJECTS = $(sort $(SCANNER_OBJECTS) $(HASH_OBJECTS) driver.o)

.PHONY: all clean
all: subc

subc: $(OBJECTS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJECTS) $(LDLIBS)

$(OBJECTS): subc.h
lex.yy.c: subc.l
	$(LEX) -o $@ $<

clean:
	rm -f $(OBJECTS) lex.yy.c subc
