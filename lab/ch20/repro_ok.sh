#!/usr/bin/env bash
#
# Builds firn-hello, then builds it again with `nix build --rebuild`: Nix runs
# the builder a second time in the sandbox and compares the new output with the
# one in the store. Exit status 0 means both builds produced the same bytes.
# Nothing is written outside the Nix store (--no-link).

set -o errexit
set -o nounset
set -o pipefail

main() {
  local out
  out="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#firn-hello")"
  echo "first build:  ${out}"
  nix build --no-link --print-out-paths --rebuild "${FIRN_ROOT}#firn-hello"
  echo "rebuild: identical output"
}

main "$@"
