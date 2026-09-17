#include "greeting.h"

#include <stdio.h>

enum { GREETING_MAX = 64 };

int main(void) {
  char buf[GREETING_MAX];

  greeting_format(buf, sizeof buf, "world");
  puts(buf);
  return 0;
}
