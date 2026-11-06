#!/usr/bin/env bash
#
# Runs nixpkgs-hammer (nixpkgs-hammering) on cairn inside the worktree. The
# tool evaluates the attribute from the current directory (-f defaults to the
# working directory) and prints one block per finding; no output means no
# finding. Some checks need a build log of the package; they are skipped
# with a notice when the package has not been built by this Nix store, and
# the lab prints whatever the tool says. Host only.

set -o errexit
set -o nounset
set -o pipefail

FIRN_NIXPKGS="${FIRN_NIXPKGS:-${HOME}/.cache/firn/nixpkgs}"
export FIRN_NIXPKGS
bash "${FIRN_ROOT}/scripts/nixpkgs-worktree.sh" >/dev/null 2>&1
cd "${FIRN_NIXPKGS}"

echo "== nixpkgs-hammer --help (usage line)"
nixpkgs-hammer --help | grep '^Usage:'

echo
echo "== nixpkgs-hammer cairn"
status=0
nixpkgs-hammer cairn 2>&1 | sed -E 's|/nix/store/[a-z0-9]{32}-||g'
status="${PIPESTATUS[0]}" || true
echo "exit status: ${status}"
((status == 0))
