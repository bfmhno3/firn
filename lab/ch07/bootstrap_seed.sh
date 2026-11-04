#!/usr/bin/env bash
#
# Walks the derivation closure of the pinned stdenv (`nix-store -qR` of
# stdenv.drvPath; no build needed): how many derivations it holds, how many
# are fixed-output (sources), the part below bootstrap-stage0-stdenv-linux
# (built by `pkgs.minimal-bootstrap`) and the one pre-compiled binary at the
# root, the hex0 seed. Realises only that seed (a fixed-output fetch) to
# measure it.

set -o errexit
set -o nounset
set -o pipefail

readonly pkgs_nix="${FIRN_ROOT}/nix/pkgs.nix"

stdenv_drv="$(nix eval --impure --raw --expr \
  "(import ${pkgs_nix} { }).stdenv.drvPath")"
readonly stdenv_drv
echo "stdenv drv: ${stdenv_drv}"

readarray -t drvs < <(nix-store -qR "${stdenv_drv}" | grep '\.drv$')
echo "derivations in closure: ${#drvs[@]}"

fod_count="$(grep -l -- '"outputHash","[^"]' "${drvs[@]}" | wc -l)"
echo "fixed-output (fetched sources, seed, hex0): ${fod_count}"
echo "other (built by a builder): $((${#drvs[@]} - fod_count))"

names="$(printf '%s\n' "${drvs[@]}" | sed -E 's|^/nix/store/[0-9a-z]{32}-||; s|\.drv$||' | sort -u)"
echo "distinct names: $(wc -l <<<"${names}")"

echo
echo "== closure of bootstrap-stage0-stdenv-linux (the minimal-bootstrap part)"
stage0_drv="$(printf '%s\n' "${drvs[@]}" | grep -- '-bootstrap-stage0-stdenv-linux\.drv$')"
readarray -t stage0 < <(nix-store -qR "${stage0_drv}" | grep '\.drv$')
echo "stage0 drv: ${stage0_drv}"
echo "derivations in stage0 closure: ${#stage0[@]}"
printf '%s\n' "${stage0[@]}" \
  | sed -E 's|^/nix/store/[0-9a-z]{32}-||; s|\.drv$||' | sort -u \
  | tr '\n' ' ' | fold -s -w 78
echo

echo
echo "== the seed"
seed_drv="$(printf '%s\n' "${drvs[@]}" | grep -- '-hex0-seed\.drv$')"
echo "seed drv: ${seed_drv}"
seed="$(nix build --no-link --print-out-paths "${seed_drv}^*")"
echo "seed out: ${seed}"
echo "seed size: $(stat -c %s "${seed}") bytes"
echo "first derivation built from it:"
printf '%s\n' "${drvs[@]}" | grep -- '-hex0-1\.' | head -n 1
