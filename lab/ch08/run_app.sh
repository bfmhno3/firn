#!/usr/bin/env bash
#
# Runs the flake app `mini-hello` with `nix run` and prints the name of the
# flake's formatter package.

set -o errexit
set -o nounset
set -o pipefail

echo "== nix run .#mini-hello"
nix run "${FIRN_ROOT}#mini-hello"

echo
echo "== formatter name"
nix flake show --json "${FIRN_ROOT}" \
  | jq -r '.formatter."x86_64-linux".name'
