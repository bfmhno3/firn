#!/usr/bin/env bash
#
# nixpkgs `lib.foldl` (pure Nix recursion, lazy) against `lib.foldl'` (the
# builtin) on the same sum, under the default max-call-depth of 10000.

set -o errexit
set -o nounset
set -o pipefail

cd "${FIRN_ROOT}"

for f in foldl "foldl'"; do
  for n in 2000 4000 5000 20000; do
    printf '%s %s: ' "${f}" "${n}"
    nix eval --impure --expr "let l = import \"\${(import ./nix/pins.nix).nixpkgs}/lib\"; in l.${f} builtins.add 0 (l.range 1 ${n})" 2>&1 \
      | grep -E '^[0-9]+$|error: ' | sed 's/^ *//' | tail -n 1 || true
  done
done
