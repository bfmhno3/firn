CC ?= cc
PREFIX ?= /usr/local

CFLAGS ?= -O2 -Wall -Wextra

.PHONY: all install clean

all: hello-c

hello-c: src/main.c
	$(CC) $(CFLAGS) -o $@ $<

install: hello-c
	install -D -m 755 hello-c $(DESTDIR)$(PREFIX)/bin/hello-c

clean:
	rm -f hello-c
