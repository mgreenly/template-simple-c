#include "greeting.h"

#include <unity.h>

enum { HELLO_WORLD_LEN = 13, ROOMY = 32, TIGHT = 8 };

void setUp(void) {}

void tearDown(void) {}

static void formats_name(void) {
  char buf[ROOMY];

  int n = greeting_format(buf, sizeof buf, "world");

  TEST_ASSERT_EQUAL_STRING("Hello, world!", buf);
  TEST_ASSERT_EQUAL_INT(HELLO_WORLD_LEN, n);
}

static void truncates_to_buffer(void) {
  char buf[TIGHT];

  int n = greeting_format(buf, sizeof buf, "world");

  TEST_ASSERT_EQUAL_STRING("Hello, ", buf);
  TEST_ASSERT_EQUAL_INT(HELLO_WORLD_LEN, n);
}

int main(void) {
  UNITY_BEGIN();
  RUN_TEST(formats_name);
  RUN_TEST(truncates_to_buffer);
  return UNITY_END();
}
