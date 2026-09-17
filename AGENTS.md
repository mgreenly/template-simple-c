This project is spec managed.  Direct source code changes are not allowed
without direct user instruction. Agents should never start the build loop
this is strictly a human gated operation.

This project requires squash merges to main.

## Toolchain

gcc 14, clang-format 19, clang-tidy 19, cppcheck 2.17, valgrind 3.24, lcov 2.0, GNU make 4.4.

## Layout

- `src/` holds all our code. A package is a subdirectory, created only when large enough.
- Headers sit beside their `.c`. Includes are quoted and relative to the including file. No `-I`.
- `src/<name>_test.c` is the unit test for `src/<name>.c`, beside it. Every product file except `main.c` has one.
- `vendor/<name>/` holds third-party code, included with angle brackets via `-isystem`, built with relaxed flags.
- System libraries come through `pkg-config` or `-l`, scoped to the targets that need them.

## Rules

- One build, `-O2 -g`, no debug mode. `make release` strips symbols into `bin/hello.debug`.
- `NDEBUG` is never defined. Asserts are always live, so they must be cheap and side-effect free.
- Magic numbers are named. Buffer sizes are enum constants.
- No suppression comments of any kind. A finding that cannot be fixed is filed as an issue.

## Test files

`src/**/*_test.c`

## Gates

Run in this order. Each must exit 0. Silent on success.

```
make check-tools
make check-fmt
make check-build
make check-test
make check-analyze
make check-cppcheck
make check-tidy
make check-sanitize
make check-valgrind
make check-coverage
```

`make check` runs all of them and stops at the first failure. `make help` lists every target.

## Commit conventions

```
<imperative summary, <=50 chars>

<optional: one or two lines on what changed and why>

Requirements: R-XXXX-XXXX, R-YYYY-YYYY
```
