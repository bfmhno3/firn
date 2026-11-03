#!/usr/bin/env bash
#
# Counts the top-level attributes of the pinned nixpkgs and times the
# evaluation (forces the attribute names only, not the packages).

set -o errexit
set -o nounset
set -o pipefail

expr="builtins.length (builtins.attrNames (import ${FIRN_ROOT}/nix/pkgs.nix { }))"
start="${EPOCHREALTIME/./}"
count="$(nix eval --impure --expr "${expr}")"
end="${EPOCHREALTIME/./}"
echo "top-level attributes: ${count}"
echo "eval time: $(((end - start) / 1000)) ms"
echo "== line counts"
cd "${FIRN_ROOT}"
wc -l flake.nix scripts/chapter.sh nix/*.nix
