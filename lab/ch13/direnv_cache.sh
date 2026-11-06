#!/usr/bin/env bash
#
# What nix-direnv's cache buys. A project from the c template lives in
# LAB_TMP with the .envrc `use flake`; direnv is confined to LAB_TMP through
# the XDG_* variables (fixtures/direnv_project.sh), and its direnvrc sources
# $FIRN_NIX_DIRENV, the nix-direnv file the firn dev shell exports. Timings
# of `direnv exec . true`: the first call (nothing cached: evaluate the flake,
# build the profile), then the median of 5 further calls with the cache, then
# the median of 5 calls with plain direnv (no nix-direnv: the built-in
# `use flake` runs `nix print-dev-env` again on every call). Milliseconds and
# ratios are volatile.

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=lab/ch13/fixtures/direnv_project.sh
source "${FIRN_ROOT}/lab/ch13/fixtures/direnv_project.sh"

#######################################
# Time one `direnv exec . true` in milliseconds.
# Outputs:
#   The elapsed time as an integer.
#######################################
time_ms() {
  local start end
  start="${EPOCHREALTIME/./}"
  direnv exec . true >/dev/null 2>&1
  end="${EPOCHREALTIME/./}"
  echo $(((end - start) / 1000))
}

#######################################
# Median of 5 timings.
#######################################
median5() {
  local _
  for _ in 1 2 3 4 5; do
    time_ms
  done | sort -n | sed -n 3p
}

main() {
  local first cached plain
  direnv_project::setup with
  first="$(time_ms)"
  cached="$(median5)"
  printf 'volatile: nix-direnv first call   %6d ms\n' "${first}"
  printf 'volatile: nix-direnv cached (med) %6d ms\n' "${cached}"
  awk -v a="${first}" -v b="${cached}" \
    'BEGIN { printf "volatile: first / cached          %6.1f x\n", a / b }'

  rm -rf "${LAB_TMP}/proj" "${LAB_TMP}/xdg"
  direnv_project::setup without
  direnv exec . true >/dev/null 2>&1
  plain="$(median5)"
  printf 'volatile: plain direnv (med)      %6d ms\n' "${plain}"
  awk -v a="${plain}" -v b="${cached}" \
    'BEGIN { printf "volatile: plain / cached          %6.1f x\n", a / b }'
}

main "$@"
