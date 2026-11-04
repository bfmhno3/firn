#!/usr/bin/env bash
#
# The runtime closure of the pinned `hello`: every path reachable through
# references. Lists it, sizes it, draws the top of the tree and asks why
# hello depends on glibc.

set -o errexit
set -o nounset
set -o pipefail

readonly pkgs_nix="${FIRN_ROOT}/nix/pkgs.nix"

hello="$(nix build --impure --no-link --print-out-paths --expr \
  "(import ${pkgs_nix} { }).hello")"
readonly hello
echo "hello: ${hello}"

echo
echo "== nix-store -qR (closure, paths)"
nix-store -qR "${hello}"
echo "path count: $(nix-store -qR "${hello}" | wc -l)"

echo
echo "== nix path-info -rsSh (closure size, self size)"
nix path-info -rsSh "${hello}"
echo "closure size: $(nix path-info -S "${hello}" | cut -f2 | tr -d ' ') bytes"

echo
echo "== nix-store -q --tree (first 12 lines)"
nix-store -q --tree "${hello}" | sed -n 1,12p

echo
echo "== nix why-depends hello glibc"
nix why-depends "${hello}" \
  "$(nix-store -q --references "${hello}" | grep -- '-glibc-[0-9]' | head -n 1)"
