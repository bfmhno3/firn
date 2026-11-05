#!/usr/bin/env bash
#
# The flake eval cache: median of 5 runs with a cold cache, with a warm cache,
# and with `--option eval-cache false`, for two commands:
#   nix eval --raw .#legacyPackages.<system>.mini.site.outPath
#   nix path-info --derivation .#legacyPackages.<system>.mini.site
# A dirty git tree has no fingerprint and therefore no eval cache, so the
# script clones the repository (clean tree) into LAB_TMP and gives every cold
# run its own, empty XDG_CACHE_HOME. Timings are in ms; nothing is asserted.

set -o errexit
set -o nounset
set -o pipefail

system="$(nix eval --raw --impure --expr builtins.currentSystem)"
readonly system
readonly attr="legacyPackages.${system}.mini.site.outPath"
readonly runs=5

git clone --quiet "${FIRN_ROOT}" "${LAB_TMP}/clone"
cd "${LAB_TMP}/clone"

#######################################
# Time one command in milliseconds.
# Arguments:
#   Command and arguments.
# Outputs:
#   Writes the elapsed milliseconds to stdout.
#######################################
time_ms() {
  local start end
  start="$(date +%s%N)"
  "$@" >/dev/null
  end="$(date +%s%N)"
  echo $(((end - start) / 1000000))
}

#######################################
# Median of the numbers on stdin.
#######################################
median() {
  sort -n | sed -n "$(((runs + 1) / 2))p"
}

#######################################
# Time a command cold, warm and with the eval cache off, 5 runs each.
# Globals:
#   LAB_TMP, runs
# Arguments:
#   Label, then the command and its arguments.
# Outputs:
#   Writes the timings, medians and speedups to stdout.
#######################################
bench() {
  local label="$1"
  shift
  local -a cold=() warm=() off=()
  local i prime="${LAB_TMP}/prime-${label}"

  # Prime the store and the fetcher state so that no run pays for fetching:
  # one throwaway evaluation with its own cache directory.
  XDG_CACHE_HOME="${prime}" "$@" >/dev/null

  for ((i = 0; i < runs; i++)); do
    cold+=("$(XDG_CACHE_HOME="${LAB_TMP}/cold-${label}-${i}" time_ms "$@")")
  done
  # The cache directory of the priming run already holds the result.
  for ((i = 0; i < runs; i++)); do
    warm+=("$(XDG_CACHE_HOME="${prime}" time_ms "$@")")
  done
  for ((i = 0; i < runs; i++)); do
    off+=("$(XDG_CACHE_HOME="${prime}" time_ms "$@" --option eval-cache false)")
  done

  local cold_med warm_med off_med
  cold_med="$(printf '%s\n' "${cold[@]}" | median)"
  warm_med="$(printf '%s\n' "${warm[@]}" | median)"
  off_med="$(printf '%s\n' "${off[@]}" | median)"

  echo "== ${label}"
  echo "\$ $*"
  echo "cold (empty cache):      ${cold[*]} -> median ${cold_med} ms"
  echo "warm (cache filled):     ${warm[*]} -> median ${warm_med} ms"
  echo "off  (eval-cache false): ${off[*]} -> median ${off_med} ms"
  echo "ratio cold/warm: $(awk -v c="${cold_med}" -v w="${warm_med}" \
    'BEGIN { printf "%.1f", c / w }')x"
  echo "ratio off/warm:  $(awk -v c="${off_med}" -v w="${warm_med}" \
    'BEGIN { printf "%.1f", c / w }')x"
  echo
}

bench eval-outpath nix eval --raw ".#${attr}"
bench path-info-drv nix path-info --derivation ".#legacyPackages.${system}.mini.site"
