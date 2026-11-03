#!/usr/bin/env bash
#
# `nix eval --debugger` stops at builtins.break and opens a debugger prompt.
# The prompt needs a terminal, so the session runs under script(1) with
# commands on stdin: `:bt` prints the backtrace, `:env` the bindings in scope
# and `:q` leaves. nix exits non-zero after :q because the breakpoint is an
# error; that status is ignored. Host only: depends on script(1) and a pty.

set -o errexit
set -o nounset
set -o pipefail

readonly expr='let x = 40; y = x + 2; in builtins.break (x + y)'

printf ':env\n:bt\n:q\n' \
  | script -qec "nix eval --debugger --expr '${expr}'" /dev/null 2>&1 \
  | tr -d '\r' \
  | sed 's/\x1b\[[0-9;?]*[A-Za-z]//g' \
  | head -n 40 || true
