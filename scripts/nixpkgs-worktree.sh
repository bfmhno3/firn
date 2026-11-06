#!/usr/bin/env bash
#
# Builds a local nixpkgs worktree for the chapter 14 dry run: a depth-1
# checkout of the nixpkgs revision Firn pins (branch firn-base) plus one
# commit on top (branch firn-cairn) that adds pkgs/by-name/ca/cairn.
#
# Usage: scripts/nixpkgs-worktree.sh
#
# The worktree lives in ${FIRN_NIXPKGS:-${HOME}/.cache/firn/nixpkgs}. It is
# created on the first run and reused afterwards; every run resets firn-cairn
# to firn-base and recommits, so the script is idempotent. It only fetches
# from GitHub and never pushes.

set -o errexit
set -o nounset
set -o pipefail

FIRN_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly FIRN_ROOT
readonly WORKTREE="${FIRN_NIXPKGS:-${HOME}/.cache/firn/nixpkgs}"
# 与 flake.lock 里锁定的 nixpkgs 版本相同。
readonly BASE_REV=56c02bc00adcf003215cc4bd996d6efaf4cff188
readonly CAIRN_PATH=pkgs/by-name/ca/cairn/package.nix

#######################################
# Print an error message to stderr.
# Arguments:
#   Message text.
# Outputs:
#   Writes "nixpkgs-worktree.sh: <message>" to stderr.
#######################################
err() {
  printf 'nixpkgs-worktree.sh: %s\n' "$*" >&2
}

#######################################
# Create the worktree at the pinned revision when it does not exist yet.
# Globals:
#   WORKTREE, BASE_REV
# Outputs:
#   Git progress on stderr.
# Returns:
#   Non-zero if any git command fails.
#######################################
init_worktree() {
  if [[ -d "${WORKTREE}/.git" ]]; then
    return 0
  fi
  mkdir -p "${WORKTREE}" || return 1
  git -C "${WORKTREE}" -c init.defaultBranch=firn-base init --quiet || return 1
  git -C "${WORKTREE}" remote add origin \
    https://github.com/NixOS/nixpkgs.git || return 1
  git -C "${WORKTREE}" fetch --depth 1 origin "${BASE_REV}" || return 1
  git -C "${WORKTREE}" checkout -B firn-base FETCH_HEAD || return 1
}

#######################################
# Reset firn-cairn to firn-base and commit the contrib package on top.
# Globals:
#   FIRN_ROOT, WORKTREE, CAIRN_PATH
# Returns:
#   Non-zero if any git command fails.
#######################################
commit_cairn() {
  git -C "${WORKTREE}" checkout -B firn-cairn firn-base || return 1
  mkdir -p "${WORKTREE}/${CAIRN_PATH%/*}" || return 1
  cp "${FIRN_ROOT}/contrib/nixpkgs/${CAIRN_PATH}" \
    "${WORKTREE}/${CAIRN_PATH}" || return 1
  git -C "${WORKTREE}" add "${CAIRN_PATH}" || return 1
  git -C "${WORKTREE}" \
    -c user.name='Firn Lab' -c user.email='firn@example.invalid' \
    commit --quiet -m 'cairn: init at 0.1.0' || return 1
}

main() {
  init_worktree || {
    err "cannot create ${WORKTREE}"
    return 1
  }
  commit_cairn || {
    err "cannot commit cairn in ${WORKTREE}"
    return 1
  }
  printf '%s\n' "${WORKTREE}"
}

main "$@"
