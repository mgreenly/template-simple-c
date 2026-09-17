CC := gcc

CFLAGS := -std=c17 -Wall -Wextra -Wpedantic -Werror
CFLAGS += -Wshadow -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations
CFLAGS += -Wredundant-decls -Wnested-externs -Wold-style-definition
CFLAGS += -Wconversion -Wsign-conversion -Wdouble-promotion -Wcast-qual -Wcast-align=strict
CFLAGS += -Wwrite-strings -Wpointer-arith -Wbad-function-cast
CFLAGS += -Wswitch-enum -Wswitch-default -Wimplicit-fallthrough
CFLAGS += -Wduplicated-cond -Wduplicated-branches -Wlogical-op -Wnull-dereference
CFLAGS += -Winit-self -Wundef -Wdate-time -Wformat=2 -Wformat-overflow=2 -Wformat-truncation=2
CFLAGS += -Walloca -Wvla -Wstack-usage=4096 -Wframe-larger-than=4096
CFLAGS += -Warray-bounds=2 -Wstringop-overflow=4 -Wstrict-aliasing=3
CFLAGS += -fstack-protector-strong -fstack-clash-protection -fcf-protection=full
CFLAGS += -fno-common -fno-strict-overflow -fno-delete-null-pointer-checks
CFLAGS += -D_FORTIFY_SOURCE=3 -O2 -g

DEPFLAGS := -MMD -MP

LDFLAGS := -Wl,--fatal-warnings

VENDOR_CFLAGS := -std=c17 -O2 -g

VARIANT ?= default
BUILD := build/$(VARIANT)
BIN := $(if $(filter default,$(VARIANT)),bin,$(BUILD)/bin)

ifeq ($(VARIANT),sanitize)
CFLAGS += -fsanitize=address,undefined -fno-sanitize-recover=all
endif
ifeq ($(VARIANT),coverage)
CFLAGS += --coverage -O0 -U_FORTIFY_SOURCE
endif

SRCS      := $(shell find src -name '*.c')
HDRS      := $(shell find src -name '*.h')
TEST_SRCS := $(filter %_test.c,$(SRCS))
APP_SRCS  := $(filter-out %_test.c,$(SRCS))
LIB_SRCS  := $(filter-out src/main.c,$(APP_SRCS))

APP_OBJS  := $(patsubst src/%.c,$(BUILD)/%.o,$(APP_SRCS))
LIB_OBJS  := $(patsubst src/%.c,$(BUILD)/%.o,$(LIB_SRCS))
TEST_BINS := $(patsubst src/%.c,$(BIN)/%,$(TEST_SRCS))
UNITY_OBJ := $(BUILD)/unity.o

all: $(BIN)/hello ## build bin/hello (default)

$(BIN)/hello: $(APP_OBJS)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

$(BIN)/%_test: $(BUILD)/%_test.o $(LIB_OBJS) $(UNITY_OBJ)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

$(BUILD)/%_test.o: src/%_test.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(DEPFLAGS) -isystem vendor/unity -c -o $@ $<

$(BUILD)/%.o: src/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(DEPFLAGS) -c -o $@ $<

$(BUILD)/unity.o: vendor/unity/unity.c
	@mkdir -p $(@D)
	$(CC) $(VENDOR_CFLAGS) $(DEPFLAGS) -c -o $@ $<

test: $(TEST_BINS) ## build and run unit tests, verbose
	@for t in $(TEST_BINS); do ./$$t || exit 1; done

fmt: ## format sources in place
	clang-format -i $(SRCS) $(HDRS)

check: check-tools check-fmt check-build check-test check-analyze check-cppcheck check-tidy check-sanitize check-valgrind check-coverage ## run every check-* layer in order

TOOLS := $(CC) clang-format clang-tidy cppcheck valgrind lcov objcopy strip

check-tools: ## required tools are installed
	@for t in $(TOOLS); do command -v $$t >/dev/null || { echo "missing tool: $$t"; exit 1; }; done

check-fmt: ## sources are clang-formatted
	@clang-format --dry-run --Werror $(SRCS) $(HDRS)

check-build: ## app and tests compile under strict flags
	@$(MAKE) -s $(BIN)/hello $(TEST_BINS)

check-test: check-build ## unit tests pass
	@for t in $(TEST_BINS); do out=$$(./$$t 2>&1) || { echo "$$out"; exit 1; }; done

check-analyze: ## gcc -fanalyzer finds nothing
	@for f in $(SRCS); do $(CC) $(CFLAGS) -fanalyzer -isystem vendor/unity -c -o /dev/null $$f || exit 1; done

check-cppcheck: ## cppcheck finds nothing
	@cppcheck --quiet --std=c17 --error-exitcode=1 --enable=warning,style,performance,portability --check-level=exhaustive --suppress=missingIncludeSystem --template=gcc src

check-tidy: ## clang-tidy finds nothing
	@clang-tidy --quiet $(SRCS) -- -std=c17 -isystem vendor/unity 2>/dev/null

check-sanitize: ## unit tests pass under ASan and UBSan
	@$(MAKE) -s VARIANT=sanitize check-test

check-valgrind: check-build ## unit tests pass under valgrind memcheck
	@for t in $(TEST_BINS); do out=$$(valgrind -q --error-exitcode=1 --leak-check=full ./$$t 2>&1) || { echo "$$out"; exit 1; }; done

check-coverage: ## unit tests cover every line
	@$(MAKE) -s VARIANT=coverage check-test
	@out=$$(lcov --quiet --ignore-errors unused --capture --directory build/coverage --output-file build/coverage/lcov.info --exclude '*_test.c' --exclude '*/vendor/*' --exclude '/usr/*' 2>&1) || { echo "$$out"; exit 1; }
	@lcov --summary build/coverage/lcov.info --fail-under-lines 100 >/dev/null 2>&1 || { lcov --list build/coverage/lcov.info 2>/dev/null; exit 1; }

release: bin/hello ## strip bin/hello, keep symbols in bin/hello.debug
	objcopy --only-keep-debug bin/hello bin/hello.debug
	strip bin/hello
	objcopy --add-gnu-debuglink=bin/hello.debug bin/hello

clean: ## remove build outputs
	rm -rf bin build

help: ## list targets
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-16s %s\n", $$1, $$2}'

-include $(APP_OBJS:.o=.d) $(patsubst src/%.c,$(BUILD)/%.d,$(TEST_SRCS))

.PHONY: all test fmt help check check-tools check-fmt check-build check-test check-analyze check-cppcheck check-tidy check-sanitize check-valgrind check-coverage release clean
.SECONDARY:
