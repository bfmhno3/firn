#!/usr/bin/env bash
#
# Builds `mini.hello` with the legacy CLI (`nix-build -A`, via default.nix) and
# with the new one (`nix build .#legacyPackages.<sys>.mini.hello`). Both give
# one out path, because the derivation is the same. Then shows that the
# `result` symlink nix-build leaves behind is a GC root: nix-store lists it,
# and a store path with such a root is alive. Everything happens in LAB_TMP.

set -o errexit
set -o nounset
set -o pipefail

system="$(nix eval --raw --impure --expr builtins.currentSystem)"
readonly system

echo "== nix-build -A mini.hello"
legacy="$(nix-build "${FIRN_ROOT}" -A mini.hello)"
readonly legacy
echo "${legacy}"

echo
echo "== nix build .#legacyPackages.${system}.mini.hello --print-out-paths"
flake="$(nix build "${FIRN_ROOT}#legacyPackages.${system}.mini.hello" \
  --print-out-paths --out-link flake-result)"
readonly flake
echo "${flake}"

echo
if [[ "${legacy}" == "${flake}" ]]; then
  echo "same out path"
else
  echo "DIFFERENT out paths"
fi

echo
echo "== ls -l result flake-result"
# shellcheck disable=SC2012  # `ls -l` shows the links, as the post does
ls -l result flake-result | awk '{print $9, $10, $11}'

echo
echo "== roots under this directory (nix-store --gc --print-roots)"
nix-store --gc --print-roots | grep -F "${PWD}/" | sed "s|\"${PWD}/|\"<LAB_TMP>/|" | sort

echo
echo "== why the store path stays alive (nix-store -q --roots)"
nix-store -q --roots "${legacy}" | grep -F "${PWD}/" | sed "s|^${PWD}/|<LAB_TMP>/|" | sort
