CC = gcc
CPPFLAGS = -I./ext/include
CFLAGS = -Wall -Wextra -Wmissing-declarations -std=c99 -pedantic -O3
LDFLAGS = -L./ext/lib -s

SRCFILES = $(wildcard *.c)

all: attackCPA

attackCPA: LDLIBS += -lm -ltraceio -lCPA

clean:
	rm -f attackCPA

.PHONY: all clean
