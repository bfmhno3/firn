#!/usr/bin/env bash
#
# Asks the public Cachix cache bfmhno3-firn whether it has pebble's output path
# (`nix path-info --store https://bfmhno3-firn.cachix.org`, a read-only
# request), then substitutes pebble into an empty local store in LAB_TMP and
# times it. The cold build of pebble took 253.4 s on this host (chapter 11).
# The cache is filled by the CI workflow, so until CI has run on a push that
# includes this chapter the path is missing and the lab says so instead of
# timing anything.

set -o errexit
set -o nounset
set -o pipefail

readonly CACHE="https://bfmhno3-firn.cachix.org"
readonly CACHE_KEY="bfmhno3-firn.cachix.org-1:LqoBOb9Jvs/LrrTa/CxBwJG14boQsOkdBEABj+M3GBI="
readonly NIXOS_KEY="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

main() {
  local out
  out="$(nix eval --raw "${FIRN_ROOT}#pebble.outPath")"
  echo "pebble: ${out}"
  if ! nix path-info --store "${CACHE}" "${out}"; then
    echo "cachix: MISS (CI has not pushed this path yet)"
    return 0
  fi
  echo "cachix: HIT"

  local start end
  start="$(date +%s%N)"
  nix build --store "${LAB_TMP}/s" --no-link \
    --option substituters "${CACHE} https://cache.nixos.org" \
    --option trusted-public-keys "${CACHE_KEY} ${NIXOS_KEY}" \
    "${FIRN_ROOT}#pebble"
  end="$(date +%s%N)"
  echo "volatile: substituted into a fresh store in $(((end - start) / 1000000)) ms"
  echo "volatile: cold build recorded in chapter 11: 253.4 s"
  nix path-info --store "${LAB_TMP}/s" "${out}"
}

main "$@"
