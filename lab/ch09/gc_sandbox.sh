#!/usr/bin/env bash
#
# Garbage collection, safely: in a throwaway store under LAB_TMP. Two paths
# are added; one gets a GC root (`nix-store --add-root`), the other does not.
# `nix store gc` deletes only the unrooted one. Then the root is removed and
# the second collection deletes the rest. This is exactly what `result`
# symlinks do on the host: as long as a root points at a path, it lives.

set -o errexit
set -o nounset
set -o pipefail

readonly store="${LAB_TMP}/store"

echo keep >keep.txt
echo drop >drop.txt
kept="$(nix store add --store "${store}" keep.txt)"
nix store add --store "${store}" drop.txt >/dev/null
readonly kept

nix-store --store "${store}" --add-root "${LAB_TMP}/root" --realise "${kept}" >/dev/null
echo "== roots: root -> $(basename "$(readlink "${LAB_TMP}/root")" | sed 's/^[a-z0-9]*-/<hash>-/')"

list_store() {
  find "${store}/nix/store" -maxdepth 1 -name '*.txt' -printf '%f\n' | sed 's/^[a-z0-9]*-/<hash>-/' | sort
}

echo
echo "== before: $(list_store | tr '\n' ' ')"
echo "== nix store gc (with the root)"
nix store gc --store "${store}" 2>&1 | grep -E 'store paths deleted' | sed 's/, .*//'
echo "after:  $(list_store | tr '\n' ' ')"

echo
echo "== rm root; nix store gc"
rm "${LAB_TMP}/root"
nix store gc --store "${store}" 2>&1 | grep -E 'store paths deleted' | sed 's/, .*//'
echo "after:  $(list_store | tr '\n' ' ')"
