#!/usr/bin/env bash
#
# What the mini stdenv hands to the builder: `nix derivation show` of the mini
# hello, projected to system, builder, args and four environment variables.

set -o errexit
set -o nounset
set -o pipefail

system="$(nix eval --raw --impure --expr builtins.currentSystem)"
readonly system

nix derivation show \
  "${FIRN_ROOT}#legacyPackages.${system}.mini.hello" 2>/dev/null \
  | jq '.derivations | to_entries[0].value
    | {system, builder, args,
      env: (.env | {buildInputs, busybox, installPhase, name})}'
