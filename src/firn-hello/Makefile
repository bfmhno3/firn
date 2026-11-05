CC ?= cc
PKG_CONFIG ?= pkg-config
PREFIX ?= /usr/local

CFLAGS ?= -O2 -Wall -Wextra
ZLIB_CFLAGS ?= $(shell $(PKG_CONFIG) --cflags zlib)
ZLIB_LIBS ?= $(shell $(PKG_CONFIG) --libs zlib)

.PHONY: all install clean

all: firn-hello

firn-hello: firn-hello.c
	$(CC) $(CFLAGS) $(ZLIB_CFLAGS) -o $@ $< $(ZLIB_LIBS)

install: firn-hello
	install -D -m 755 firn-hello $(DESTDIR)$(PREFIX)/bin/firn-hello

clean:
	rm -f firn-hello
