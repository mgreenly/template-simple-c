#ifndef GREETING_H
#define GREETING_H

#include <stddef.h>

/* Writes "Hello, <name>!" into buf. Returns the number of characters that
 * would have been written (excluding the terminator), like snprintf. */
int greeting_format(char *buf, size_t size, const char *name);

#endif
