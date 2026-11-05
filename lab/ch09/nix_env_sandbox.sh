#!/usr/bin/env bash
#
# The legacy package manager, in a profile under LAB_TMP (never the user's):
# `nix-env -iA` installs by attribute path; `nix-env -i NAME` and `-qaP NAME`
# match by *name*, which makes nix-env evaluate every package of nixpkgs
# first. The two timings below are volatile (they depend on the machine and
# the eval cache); the order of magnitude is the point: milliseconds with
# `-A`, tens of seconds without. Evaluation warnings go to stderr and are
# hidden. Generation dates are masked as <date>.

set -o errexit
set -o nounset
set -o pipefail

readonly profile="${LAB_TMP}/env"
readonly pkgs="${FIRN_ROOT}/nix/pkgs.nix"

#######################################
# Print the elapsed seconds of a command, rounded, labeled as volatile.
# Arguments:
#   Label, then the command.
#######################################
timed() {
  local label="$1"
  shift
  local start="${EPOCHREALTIME}"
  "$@" >/dev/null 2>&1
  local elapsed
  elapsed="$(awk -v a="${start}" -v b="${EPOCHREALTIME}" 'BEGIN { printf "%.1f", b - a }')"
  echo "volatile: ${label}: ${elapsed} s"
}

echo "== nix-env -iA hello"
nix-env -p "${profile}" -f "${pkgs}" -iA hello 2>&1 | grep -v '^building'
nix-env -p "${profile}" -q

echo
echo "== generations"
nix-env -p "${profile}" --list-generations | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]+/<date>/'
# shellcheck disable=SC2012  # `ls -l` shows the links, as the post does
(cd "${LAB_TMP}" && ls -l env env-*-link | awk '{print $9, $10, $11}' | sed 's|/nix/store/[a-z0-9]*-|/nix/store/<hash>-|')

echo
echo "== query by attribute path vs by name"
nix-env -qaP -f "${pkgs}" -A hello 2>/dev/null
timed "nix-env -qaP -A hello  (one attribute)" nix-env -qaP -f "${pkgs}" -A hello
timed "nix-env -qaP hello     (name: evaluates all of nixpkgs)" nix-env -qaP -f "${pkgs}" hello

echo
echo "== pitfall: nix-env -i hello (by name)"
nix-env -p "${profile}" -f "${pkgs}" -i hello 2>&1 | grep -E "^(replacing|installing)"
nix-env -p "${profile}" -q
echo "(the same package was replaced, and it cost a new generation)"
nix-env -p "${profile}" --list-generations | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]+/<date>/'

echo
echo "== uninstall, then roll back"
nix-env -p "${profile}" -e hello 2>&1 | grep -v '^building'
echo "installed after -e: $(nix-env -p "${profile}" -q | wc -l)"
nix-env -p "${profile}" --rollback 2>&1
echo "installed after rollback: $(nix-env -p "${profile}" -q | tr '\n' ' ')"
