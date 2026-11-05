#!/usr/bin/env bash
#
# The flake of pure_eval_fail.sh evaluated with --impure: currentSystem is back.

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=lab/ch08/fixtures/currentsystem_flake.sh
source "${FIRN_ROOT}/lab/ch08/fixtures/currentsystem_flake.sh"
write_flake

echo
echo "== nix eval --impure path:${LAB_TMP}/cs#system"
nix eval --impure "path:${LAB_TMP}/cs#system"
