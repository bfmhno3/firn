#!/usr/bin/env bash
#
# Two different limits on naive recursion: max-call-depth (default 10000, a
# counter in the evaluator) and the real C++ stack (8 MiB here). Raising
# max-call-depth moves the failure from the first to the second.

set -o errexit
set -o nounset
set -o pipefail

readonly sum_to='let sumTo = n: if n == 0 then 0 else n + sumTo (n - 1); in sumTo'

#######################################
# Evaluate sumTo N with extra nix options and print the result or the error.
# Arguments:
#   N, then extra arguments for nix eval.
# Outputs:
#   Writes "<N> [options]: <result or last error line>" to stdout.
#######################################
try_depth() {
  local n="$1"
  shift
  local out
  out="$(nix eval "$@" --expr "${sum_to} ${n}" 2>&1 | grep -E '^[0-9]+$|^error: ' | tail -n 1)" || true
  echo "${n} [$*]: ${out}"
}

echo "max-call-depth default: $(nix config show max-call-depth)"
try_depth 9999
try_depth 10000
try_depth 20000 --option max-call-depth 1000000
try_depth 100000 --option max-call-depth 1000000
echo "stack limit: $(ulimit -s) KiB"
