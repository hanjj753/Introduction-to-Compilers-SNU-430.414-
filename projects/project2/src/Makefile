CC = cc
LEX = flex
YACC = bison
CFLAGS = -std=c11 -Wall -Wextra -Wpedantic -g
CPPFLAGS =
LDFLAGS =
LDLIBS =
LFLAGS =
YFLAGS = -d -v
# Add helper objects here as in Project 1.
SCANNER_OBJECTS = lex.yy.o
HASH_OBJECTS = hash.o
PARSER_OBJECTS = subc.tab.o
OBJECTS = $(sort $(SCANNER_OBJECTS) $(HASH_OBJECTS) $(PARSER_OBJECTS) driver.o)

.PHONY: all clean
all: subc

subc: $(OBJECTS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJECTS) $(LDLIBS)

# Helpers in any object list may include Bison's generated token header.
# .d files track later edits, but do not exist before the first compilation.
$(OBJECTS): subc.h subc.tab.h
%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -MMD -MP -c -o $@ $<
lex.yy.c: subc.l
	$(LEX) $(LFLAGS) -o $@ $<
# A grouped target prevents duplicate Bison invocations with make -j.
subc.tab.c subc.tab.h &: subc.y
	$(YACC) $(YFLAGS) subc.y

clean:
	rm -f $(OBJECTS) $(OBJECTS:.o=.d) lex.yy.c subc.tab.c subc.tab.h subc.output subc

# Track headers included by student helpers, including headers in subdirectories.
-include $(OBJECTS:.o=.d)
