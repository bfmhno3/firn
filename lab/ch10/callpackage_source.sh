#!/usr/bin/env bash
#
# Prints the core of `lib.callPackageWith` from the pinned nixpkgs: the part
# that intersects the wanted arguments (`functionArgs`) with the package set,
# merges the explicit arguments, and wraps the call in `makeOverridable`.
# Then calls callPackage with a missing argument to show the error message.

set -o errexit
set -o nounset
set -o pipefail

nixpkgs="$(nix eval --raw --file "${FIRN_ROOT}/nix/pins.nix" nixpkgs)"
readonly nixpkgs
file="${nixpkgs}/lib/customisation.nix"
readonly file

echo "== lib/customisation.nix: callPackageWith (core)"
awk '
  /^  callPackageWith =/ { in_fn = 1 }
  in_fn && /^    autoArgs: fn: args:/ { show = 1 }
  show { print }
  show && /abort \(makeErrorMessage/ { exit }
' "${file}"

echo
echo "== a function whose argument pkgs does not have"
# The `abort` cannot be caught, so the message comes from stderr.
nix eval --impure --expr "
  let
    pkgs = import ${FIRN_ROOT}/nix/pkgs.nix { };
  in
  pkgs.callPackage ({ zlib, zliib }: zlib) { }
" 2>&1 | sed -n "s/.*\(lib\.customisation\.callPackageWith[^']*\)'.*/\1/p" || true
