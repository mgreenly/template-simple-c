#include "greeting.h"

#include <stdio.h>

int greeting_format(char *buf, size_t size, const char *name) {
  return snprintf(buf, size, "Hello, %s!", name);
}
