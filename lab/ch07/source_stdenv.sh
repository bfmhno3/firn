#!/usr/bin/env bash
#
# Reads the nixpkgs stdenv sources at the pin: numbered listings of
# pkgs/stdenv/generic/source-stdenv.sh and default-builder.sh, and the
# function bodies of generic/setup.sh ranked by length (an awk pass: a
# function starts at `name() {` in column 0 and ends at the next `}` in
# column 0).

set -o errexit
set -o nounset
set -o pipefail

nixpkgs="$(nix eval --impure --raw --expr \
  "(import ${FIRN_ROOT}/nix/pins.nix).nixpkgs")"
readonly nixpkgs
readonly generic="${nixpkgs}/pkgs/stdenv/generic"

for file in source-stdenv.sh default-builder.sh; do
  echo "== pkgs/stdenv/generic/${file}"
  nl -ba "${generic}/${file}"
  echo
done

functions() {
  awk '
    /^[a-zA-Z_]+\(\) \{/ { name = $1; sub(/\(\)$/, "", name); start = NR }
    /^\}/ && name != "" { print NR - start + 1, name; name = "" }
  ' "${generic}/setup.sh"
}

echo "== five longest functions of setup.sh (lines, name)"
functions | sort -k1,1nr -k2,2 | head -n 5
echo
echo "== runHook and exitHandler"
functions | grep -E ' (runHook|exitHandler)$' | sort -k2,2
