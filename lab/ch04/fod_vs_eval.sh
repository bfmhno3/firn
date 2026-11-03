#!/usr/bin/env bash
#
# The same download two ways: builtins.fetchurl downloads during evaluation,
# the fixed-output derivation from <nix/fetchurl.nix> only on `nix build`.
# The store names carry a timestamp so neither path exists at the start.

set -o errexit
set -o nounset
set -o pipefail

readonly url="https://github.com/bfmhno3/cairn/archive/refs/tags/ch08.tar.gz"
readonly hash="sha256-tJN8k7bw4BvXCJPMHFnO9hwmE9xRDwdn91i0bBxNwgo="
readonly stamp="${EPOCHREALTIME/./}"
readonly fod="import <nix/fetchurl.nix> {
  url = \"${url}\"; hash = \"${hash}\"; name = \"fod-${stamp}.tar.gz\";
}"
readonly eval_fetch="builtins.fetchurl {
  url = \"${url}\"; sha256 = \"${hash}\"; name = \"eval-${stamp}.tar.gz\";
}"

#######################################
# Print "yes" or "no" depending on whether the store path exists.
# Arguments:
#   Store path.
#######################################
exists() {
  if [[ -e "$1" ]]; then echo yes; else echo no; fi
}

#######################################
# Wall time of a command in milliseconds.
# Arguments:
#   Command and its arguments.
# Outputs:
#   Writes the elapsed milliseconds to stdout.
#######################################
ms() {
  local start="${EPOCHREALTIME/./}"
  "$@" >/dev/null 2>&1
  echo $(((${EPOCHREALTIME/./} - start) / 1000))
}

fod_out="$(nix eval --pure-eval --raw --expr "(${fod}).outPath")"
echo "FOD out path:           ${fod_out}"
echo "present at start:       $(exists "${fod_out}")"
echo "eval drvPath:           $(ms nix eval --pure-eval --expr "(${fod}).drvPath") ms"
echo "present after eval:     $(exists "${fod_out}")"
echo "nix build:              $(ms nix build --no-link --impure --expr "${fod}") ms"
echo "present after build:    $(exists "${fod_out}")"
nix derivation show --impure --expr "${fod}" \
  | jq -c '.derivations | to_entries[0].value | {builder, outputs}'

eval_out="$(nix eval --pure-eval --raw --expr "${eval_fetch}")"
echo "builtins.fetchurl:      ${eval_out}"
echo "present after the eval: $(exists "${eval_out}")"
