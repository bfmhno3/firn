#!/usr/bin/env bash
#
# Runs nixpkgs-vet on the worktree (firn-cairn) against a checkout of
# firn-base, the way the nixpkgs CI does for a PR. `nixpkgs-vet --base <BASE>
# <NIXPKGS>` takes two directories, so the base is a temporary git worktree
# under LAB_TMP. The tool reads the Nix package to evaluate with from
# NIXPKGS_VET_NIX_PACKAGE (nixpkgs CI sets it; without it the tool stops
# with "I/O error"). The first version of the contrib package failed here
# with NPV-164 (strictDeps) and NPV-166 (__structuredAttrs); both are now set.
# Host only.

set -o errexit
set -o nounset
set -o pipefail

FIRN_NIXPKGS="${FIRN_NIXPKGS:-${HOME}/.cache/firn/nixpkgs}"
export FIRN_NIXPKGS
bash "${FIRN_ROOT}/scripts/nixpkgs-worktree.sh" >/dev/null 2>&1

echo "== nixpkgs-vet --help (usage line)"
nixpkgs-vet --help | grep '^Usage:'

base="${LAB_TMP}/base"
git -C "${FIRN_NIXPKGS}" worktree add --detach "${base}" firn-base >/dev/null 2>&1
trap 'git -C "${FIRN_NIXPKGS}" worktree remove --force "${base}"' EXIT

NIXPKGS_VET_NIX_PACKAGE="$(dirname "$(dirname "$(readlink -f "$(command -v nix)")")")"
export NIXPKGS_VET_NIX_PACKAGE

echo
echo "== nixpkgs-vet --base <firn-base> <firn-cairn>"
status=0
nixpkgs-vet --base "${base}" "${FIRN_NIXPKGS}" 2>&1 || status=$?
echo "exit status: ${status}"
((status == 0))
