#!/usr/bin/env bash
#
# Flake evaluation is pure: builtins.currentSystem does not exist. The temp
# flake reads it; `nix eval` prints the error and the script exits 1.

set -o nounset
set -o pipefail

# shellcheck source=lab/ch08/fixtures/currentsystem_flake.sh
source "${FIRN_ROOT}/lab/ch08/fixtures/currentsystem_flake.sh"
write_flake

echo
echo "== nix eval path:${LAB_TMP}/cs#system"
if nix eval "path:${LAB_TMP}/cs#system" 2>&1; then
  echo 'unexpected: eval succeeded' >&2
  exit 0
fi
exit 1
