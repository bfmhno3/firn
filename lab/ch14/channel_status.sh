#!/usr/bin/env bash
#
# Asks channels.nixos.org which nixpkgs commit each channel points at, asks
# GitHub for that commit's date, and prints how old each channel is today
# and how many days its commit date is after the pin's commit date (flake.lock).
# That is a difference of two dates, not git ancestry: a release channel such
# as nixos-26.05 lives on release-26.05, which has diverged from master, so
# `gh api repos/NixOS/nixpkgs/compare/<pin>...<rev>` reports it as diverged. The URL
# redirects to releases.nixos.org, hence curl -L. Read-only network use; the
# GitHub calls go through `gh api` and are skipped with a message when the
# rate limit is hit. Every number here moves every day.

set -o errexit
set -o nounset
set -o pipefail

readonly CHANNELS=(nixos-unstable nixpkgs-unstable nixos-26.05)
readonly API=repos/NixOS/nixpkgs/commits

#######################################
# Print the committer date of a nixpkgs commit as epoch seconds.
# Arguments:
#   Commit hash.
# Outputs:
#   Epoch seconds on stdout, "unavailable" if gh api fails.
#######################################
commit_epoch() {
  local iso
  if ! iso="$(gh api "${API}/$1" --jq .commit.committer.date 2>/dev/null)"; then
    echo unavailable
    return 0
  fi
  date -u -d "${iso}" +%s
}

#######################################
# Print a day count between two epoch values, or "unavailable".
# Arguments:
#   Later epoch, earlier epoch.
#######################################
days_between() {
  if [[ "$1" == unavailable || "$2" == unavailable ]]; then
    echo unavailable
  else
    printf '%d.%d\n' $((($1 - $2) / 86400)) $(((($1 - $2) % 86400) * 10 / 86400))
  fi
}

main() {
  local pin now pin_epoch ch rev epoch
  pin="$(jq -r '.nodes.nixpkgs.locked.rev' "${FIRN_ROOT}/flake.lock")"
  now="$(date -u +%s)"
  pin_epoch="$(commit_epoch "${pin}")"

  echo "pin: ${pin}"
  echo "volatile: today $(date -u +%F)"
  echo "volatile: pin age in days $(days_between "${now}" "${pin_epoch}")"
  for ch in "${CHANNELS[@]}"; do
    rev="$(curl -sSL "https://channels.nixos.org/${ch}/git-revision")" || rev=""
    if [[ ! "${rev}" =~ ^[0-9a-f]{40}$ ]]; then
      echo "volatile: ${ch}: no git-revision (${rev:0:60})"
      continue
    fi
    epoch="$(commit_epoch "${rev}")"
    echo "volatile: ${ch}: ${rev}"
    echo "volatile: ${ch}: age in days $(days_between "${now}" "${epoch}")"
    echo "volatile: ${ch}: commit date minus pin commit date, days $(days_between "${epoch}" "${pin_epoch}")"
  done
}

main "$@"
