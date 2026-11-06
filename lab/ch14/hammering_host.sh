#!/usr/bin/env bash
#
# Runs nixpkgs-hammer (nixpkgs-hammering) on cairn inside the worktree. The
# tool evaluates the attribute from the current directory (-f defaults to the
# working directory) and prints one block per attribute: findings, or
# "No issues found.". What it prints also depends on whether the package's
# output path is in the Nix store, measured on this machine: with cairn
# built it prints the notice "no-build-output ... has not yet been built.
# Checks that rely on the presence of build logs are skipped."; with an
# output path that is not in the store (a variant whose derivation differs)
# it prints "No issues found." and no notice. The lab shows both. We did not
# find out why from the tool's output; treat the reason as unverified. Host
# only.

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

echo
echo "== the same on a variant whose output is not in the store"
tree="${LAB_TMP}/variant"
git -C "${FIRN_NIXPKGS}" worktree add --detach "${tree}" firn-cairn >/dev/null 2>&1
trap 'git -C "${FIRN_NIXPKGS}" worktree remove --force "${tree}"' EXIT
# 在 preCheck 里加一条带进程号的注释，让 derivation 每次都不同；不构建，
# 输出路径一定不在 store 里。
sed -i "s/^    patchShebangs bin\$/    patchShebangs bin # probe $$/" \
  "${tree}/pkgs/by-name/ca/cairn/package.nix"
(cd "${tree}" && nixpkgs-hammer cairn 2>&1) \
  | sed -E 's|/nix/store/[a-z0-9]{32}-||g'

((status == 0))
