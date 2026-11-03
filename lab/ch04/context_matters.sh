#!/usr/bin/env bash
#
# A text file that mentions hello's store path. With string context the
# output records hello as a reference (and so keeps it alive under garbage
# collection); with the context discarded it records nothing, and `nix-store
# --gc` would be free to delete hello while the file still names it.

set -o errexit
set -o nounset
set -o pipefail

readonly pkgs_nix="${FIRN_ROOT}/nix/pkgs.nix"

#######################################
# Build a writeText file whose body mentions hello.
# Arguments:
#   Name of the file, then "keep" or "discard" the string context.
# Outputs:
#   Writes the store path of the result to stdout.
#######################################
build_text() {
  local name="$1" mode="$2" body
  # shellcheck disable=SC2016 # ${...} is Nix interpolation, not shell
  if [[ "${mode}" == keep ]]; then
    body='"uses ${pkgs.hello}/bin/hello"'
  else
    body='"uses ${builtins.unsafeDiscardStringContext (toString pkgs.hello)}/bin/hello"'
  fi
  nix build --impure --no-link --print-out-paths --expr "
    let pkgs = import ${pkgs_nix} { };
    in pkgs.writeText \"${name}\" ${body}
  "
}

hello="$(nix eval --impure --raw --expr "(import ${pkgs_nix} { }).hello.outPath")"
echo "hello: ${hello}"

kept="$(build_text ctx-kept keep)"
echo "== with context: ${kept}"
cat "${kept}"
echo
echo "references:"
nix-store -q --references "${kept}"

dropped="$(build_text ctx-dropped discard)"
echo "== context discarded: ${dropped}"
cat "${dropped}"
echo
echo "references:"
nix-store -q --references "${dropped}"
echo "(empty above: the closure of this file no longer contains hello)"
echo "closure size with context: $(nix-store -qR "${kept}" | wc -l) paths"
echo "closure size without context: $(nix-store -qR "${dropped}" | wc -l) paths"
