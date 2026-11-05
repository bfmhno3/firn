// SPDX-License-Identifier: MIT OR Apache-2.0
/*
 * firn-hello: print a greeting and the zlib crc32 of that greeting.
 *
 * The greeting word comes from the macro FIRN_GREETING, which the build
 * sets with -DFIRN_GREETING="...". Without it the word is "Hello".
 */
#include <stdio.h>
#include <string.h>
#include <zlib.h>

#ifndef FIRN_GREETING
#define FIRN_GREETING "Hello"
#endif

#define FIRN_VERSION "0.1.0"
#define USAGE "usage: firn-hello [--version] [NAME]\n"

int main(int argc, char **argv)
{
	char line[256];
	uLong crc;
	int len;

	if (argc > 2) {
		fputs(USAGE, stderr);
		return 2;
	}

	if (argc == 2 && strcmp(argv[1], "--version") == 0) {
		printf("firn-hello %s (zlib %s)\n", FIRN_VERSION,
		       zlibVersion());
		return 0;
	}

	len = snprintf(line, sizeof(line), "%s, %s, from firn-hello %s",
		       FIRN_GREETING, argc == 2 ? argv[1] : "world",
		       FIRN_VERSION);
	if (len < 0 || (size_t)len >= sizeof(line)) {
		fputs("firn-hello: name too long\n", stderr);
		return 2;
	}

	crc = crc32(0L, (const Bytef *)line, (uInt)len);
	printf("%s\ncrc32: %08lx\n", line, crc);
	return 0;
}
