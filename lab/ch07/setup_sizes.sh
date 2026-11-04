#!/usr/bin/env bash
#
# Size of the two setup.sh files: mini/stdenv/setup.sh against nixpkgs'
# pkgs/stdenv/generic/setup.sh at the pin (from nix/pins.nix). Prints line
# counts, the number of function definitions in each, and numbered excerpts
# of the nixpkgs file.

set -o errexit
set -o nounset
set -o pipefail

readonly mini_setup="${FIRN_ROOT}/mini/stdenv/setup.sh"

nixpkgs="$(nix eval --impure --raw --expr \
  "(import ${FIRN_ROOT}/nix/pins.nix).nixpkgs")"
readonly nixpkgs
readonly real_setup="${nixpkgs}/pkgs/stdenv/generic/setup.sh"

echo "== wc -l"
echo "mini:    $(wc -l <"${mini_setup}")"
echo "nixpkgs: $(wc -l <"${real_setup}")"

echo
echo "== function definitions (grep -c '^[a-zA-Z_]*() {')"
echo "mini:    $(grep -c '^[a-zA-Z_]*() {' "${mini_setup}" || true)"
echo "nixpkgs: $(grep -c '^[a-zA-Z_]*() {' "${real_setup}" || true)"

for range in 696,697 808,825 1777,1785 1817,1819; do
  echo
  echo "== pkgs/stdenv/generic/setup.sh lines ${range/,/-}"
  sed -n "${range}p" "${real_setup}" | nl -ba -v"${range%,*}"
done
