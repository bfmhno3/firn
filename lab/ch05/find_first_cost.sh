#!/usr/bin/env bash
#
# Firn's recursive findFirst (builtins.tail copies the rest of the list each
# step) against nixpkgs' foldl'-based one. First the evaluator statistics
# when searching for the last of 9000 elements, then the 20000-element case
# that hits max-call-depth in Firn's version. cpuTime varies from run to run;
# the ratios below are computed from this run's numbers only.

set -o errexit
set -o nounset
set -o pipefail

cd "${FIRN_ROOT}"

readonly firn_lib='import ./lib'
# shellcheck disable=SC2016  # ${...} is Nix interpolation, expanded by nix
readonly nixpkgs_lib='import "${(import ./nix/pins.nix).nixpkgs}/lib"'

#######################################
# Evaluator statistics of findFirst over 1..N, searching for N.
# Arguments:
#   Lib expression, N.
# Outputs:
#   Writes one JSON object per line to stdout.
#######################################
stats() {
  NIX_SHOW_STATS=1 nix eval --impure \
    --expr "let lib = $1; in lib.findFirst (x: x == $2) 0 (lib.range 1 $2)" 2>&1 >/dev/null \
    | jq -c '{nrThunks, nrFunctionCalls, cpuTime, totalBytes: .gc.totalBytes}'
}

firn="$(stats "${firn_lib}" 9000)"
nixpkgs="$(stats "${nixpkgs_lib}" 9000)"
echo "firn:    ${firn}"
echo "nixpkgs: ${nixpkgs}"
jq -nr --argjson a "${firn}" --argjson b "${nixpkgs}" \
  '"allocation ratio: \($a.totalBytes / $b.totalBytes | floor)x, cpu ratio: \(($a.cpuTime / $b.cpuTime * 10 | round) / 10)x, bytes per step: \($a.totalBytes / 9000 | floor)"'

echo "== 20000 elements"
printf 'firn: '
nix eval --impure --expr "let lib = ${firn_lib}; in lib.findFirst (x: x == 20000) 0 (lib.range 1 20000)" 2>&1 \
  | grep 'error: stack' | sed 's/^ *//' || true
printf 'nixpkgs: '
nix eval --impure --expr "let lib = ${nixpkgs_lib}; in lib.findFirst (x: x == 20000) 0 (lib.range 1 20000)"
