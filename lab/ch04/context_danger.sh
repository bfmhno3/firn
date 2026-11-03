#!/usr/bin/env bash
#
# Build a text file that names a dependency, keeping or discarding the
# string context, and check whether the dependency exists afterwards.

set -o errexit
set -o nounset
set -o pipefail

readonly pkgs_nix="${FIRN_ROOT}/nix/pkgs.nix"
readonly stamp="${EPOCHREALTIME/./}"

#######################################
# Build a file whose body names a never-built dependency.
# Arguments:
#   "keep" or "discard" the string context.
# Outputs:
#   Writes the store path of the text file to stdout.
#######################################
build_user() {
  local mode="$1" ref
  # shellcheck disable=SC2016 # ${...} is Nix interpolation, not shell
  if [[ "${mode}" == keep ]]; then
    ref='${dep}'
  else
    ref='${builtins.unsafeDiscardStringContext dep.outPath}'
  fi
  nix build --impure --no-link --print-out-paths --expr "
    let
      pkgs = import ${pkgs_nix} { };
      dep = pkgs.runCommand \"dep-${mode}-${stamp}\" { } \"echo built > \\\$out\";
    in pkgs.writeText \"user-${mode}-${stamp}\" \"depends on ${ref}\"
  " 2>/dev/null
}

for mode in keep discard; do
  user="$(build_user "${mode}")"
  dep="$(sed 's/^depends on //' "${user}")"
  echo "== ${mode}"
  echo "text:       $(cat "${user}")"
  if [[ -e "${dep}" ]]; then
    echo "dependency: exists ($(cat "${dep}"))"
  else
    echo "dependency: MISSING"
  fi
  echo "input drvs of the text file:"
  nix derivation show "$(nix-store -q --deriver "${user}")" \
    | jq -r '.derivations | to_entries[0].value.inputs.drvs | keys[]' \
    | sed 's/^/  /'
done
