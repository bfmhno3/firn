#!/usr/bin/env bash
#
# Runs `nixpkgs-review rev HEAD` on the worktree: it evaluates nixpkgs
# before and after the commit, finds the packages whose derivations changed
# and builds them. `rev` fetches the base from GitHub, so the base is the
# pinned revision (-b accepts a commit hash). Flags, all checked with
# `nixpkgs-review rev --help`: --no-shell (build and stop, no nix-shell),
# --print-result (print the report), --build-graph nix (no nom). The review
# directory goes under LAB_TMP through XDG_CACHE_HOME. Prints what it built.
# Host only.

set -o errexit
set -o nounset
set -o pipefail

FIRN_NIXPKGS="${FIRN_NIXPKGS:-${HOME}/.cache/firn/nixpkgs}"
export FIRN_NIXPKGS
bash "${FIRN_ROOT}/scripts/nixpkgs-worktree.sh" >/dev/null 2>&1
export XDG_CACHE_HOME="${LAB_TMP}/cache"
cd "${FIRN_NIXPKGS}"

base="$(jq -r '.nodes.nixpkgs.locked.rev' "${FIRN_ROOT}/flake.lock")"

echo "== nixpkgs-review rev HEAD -b <pin> --no-shell --print-result"
start="$(date +%s%N)"
nixpkgs-review rev HEAD -b "${base}" --no-shell --print-result \
  --build-graph nix >"${LAB_TMP}/review.out" 2>"${LAB_TMP}/review.err"
end="$(date +%s%N)"
echo "volatile: wall time $(((end - start) / 1000000)) ms"

echo
echo "== result (git, nix-eval-jobs and nix build command lines left out)"
sed -E '/^\$ /d; /^HEAD is now/d; /^Logs can be found/,/^$/d; /^Commit:/d' \
  "${LAB_TMP}/review.out"
echo "volatile: review commit $(git rev-parse HEAD)"
