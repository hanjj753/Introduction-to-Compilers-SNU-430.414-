CC = cc
LEX = flex
YACC = bison
CFLAGS = -std=c11 -Wall -Wextra -Wpedantic -g
CPPFLAGS =
LDFLAGS =
LDLIBS =
LFLAGS =
YFLAGS = -d -v
OBJECTS = lex.yy.o example.tab.o

.PHONY: all clean
all: example

example: $(OBJECTS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJECTS) $(LDLIBS)

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -MMD -MP -c -o $@ $<
lex.yy.o: example.tab.h
lex.yy.c: example.l
	$(LEX) $(LFLAGS) -o $@ $<
# Bison creates both files in one invocation, including with make -j.
example.tab.c example.tab.h &: example.y
	$(YACC) $(YFLAGS) example.y

clean:
	rm -f $(OBJECTS) $(OBJECTS:.o=.d) lex.yy.c example.tab.c example.tab.h example.output example

-include $(OBJECTS:.o=.d)
