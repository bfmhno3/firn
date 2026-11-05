#!/usr/bin/env bash
#
# How to find cargoHash: copy the package, put lib.fakeHash in it and let the
# fixed-output vendor derivation fail. The error prints `got:`; the script
# compares it with the hash committed in pkgs/pebble/package.nix.

set -o errexit
set -o nounset
set -o pipefail

pkg="${FIRN_ROOT}/pkgs/pebble/package.nix"
tmp="${LAB_TMP}/pebble.nix"
sed -E 's|cargoHash = "[^"]*";|cargoHash = lib.fakeHash;|' "${pkg}" >"${tmp}"
grep -n 'cargoHash' "${tmp}"

log="${LAB_TMP}/build.log"
if nix build --no-link --impure --expr "
  let
    pkgs = import ${FIRN_ROOT}/nix/pkgs.nix { };
  in
  pkgs.callPackage ${tmp} { }
" 2>"${log}"; then
  echo "build with fakeHash succeeded, that must not happen" >&2
  exit 1
fi
grep -E 'specified:|got:' "${log}"

got="$(sed -nE 's/^ *got: *(sha256-[^ ]*)$/\1/p' "${log}" | head -n 1)"
want="$(sed -nE 's/.*cargoHash = "([^"]*)";.*/\1/p' "${pkg}")"
echo "committed: ${want}"
[[ "${got}" == "${want}" ]] || exit 1
