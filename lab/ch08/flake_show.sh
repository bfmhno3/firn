#!/usr/bin/env bash
#
# The outputs of the Firn flake: the tree `nix flake show` prints, then the
# top-level output names from `nix flake show --json | jq 'keys'`.

set -o errexit
set -o nounset
set -o pipefail

echo '== nix flake show'
nix flake show "${FIRN_ROOT}"

echo
echo "== nix flake show --json | jq 'keys'"
nix flake show --json "${FIRN_ROOT}" | jq 'keys'

echo
echo "== apps.x86_64-linux"
nix flake show --json "${FIRN_ROOT}" | jq '.apps."x86_64-linux"'
