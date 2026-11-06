#!/usr/bin/env bash
#
# Runs scripts/nixpkgs-worktree.sh and shows the two commits it leaves on
# firn-cairn: the contribution on top of the pinned nixpkgs revision. Host
# only: the first run downloads a depth-1 checkout of nixpkgs (about 550 MB).
# Run it twice to see that the script is idempotent (the commit hash of
# firn-cairn changes with the commit time, its tree does not).

set -o errexit
set -o nounset
set -o pipefail

FIRN_NIXPKGS="${FIRN_NIXPKGS:-${HOME}/.cache/firn/nixpkgs}"
export FIRN_NIXPKGS

echo "== scripts/nixpkgs-worktree.sh"
bash "${FIRN_ROOT}/scripts/nixpkgs-worktree.sh" 2>&1 \
  | sed -E 's|^/.*/nixpkgs$|worktree: <FIRN_NIXPKGS>|'

echo
echo "== git log --oneline -2"
git -C "${FIRN_NIXPKGS}" log --oneline -2 | sed -E 's/^[0-9a-f]{9} /<hash> /'

echo
echo "== git diff --stat firn-base firn-cairn"
git -C "${FIRN_NIXPKGS}" diff --stat firn-base firn-cairn

echo
echo "== git remote -v (nothing is ever pushed)"
git -C "${FIRN_NIXPKGS}" remote -v
