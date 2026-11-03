#!/usr/bin/env bash
#
# Four kinds of error messages you meet while writing a lib: a type error,
# an error thrown by the library itself, a missing attribute, and an error
# hidden in a value (printed as «error: ...» unless something forces it).
# `grep` keeps the frame lines and the final message, dropping source
# snippets.

set -o errexit
set -o nounset
set -o pipefail

cd "${FIRN_ROOT}"

echo '== 1. type error'
nix eval --impure --expr 'let lib = import ./lib; in lib.attrByPath "a" 0 { a = 1; }' 2>&1 \
  | grep -E '^ *(error|… )' || true

echo '== 2. thrown by the library'
nix eval --impure --expr 'let lib = import ./lib; in lib.splitString "" "abc"' 2>&1 \
  | grep -E '^ *(error|… )' || true

echo '== 3. missing attribute'
nix eval --impure --expr 'let lib = import ./lib; in lib.nosuchfn' 2>&1 || true

echo '== 4. error inside a value'
nix eval --impure --expr 'let lib = import ./lib; in lib.genAttrs [ "a" ] 5'
echo "exit (printed as a value): $?"
status=0
out="$(nix eval --impure --json --expr 'let lib = import ./lib; in lib.genAttrs [ "a" ] 5' 2>&1)" || status=$?
printf '%s\n' "${out}" | grep -E '^ *error' || true
echo "exit (forced with --json): ${status}"
