#!/usr/bin/env bash
#
# Compares evaluator statistics of `hello.name` and `hello.outPath` in the
# pinned nixpkgs: the second forces the whole derivation, the first almost
# nothing. Statistics come from NIX_SHOW_STATS=1 (JSON on stderr).

set -o errexit
set -o nounset
set -o pipefail

readonly attrs_expr="builtins.length (builtins.attrNames (import ${FIRN_ROOT}/nix/pkgs.nix { }))"

#######################################
# Print selected evaluator statistics for one attribute path.
# Arguments:
#   Attribute path inside nix/pkgs.nix, e.g. hello.name.
# Outputs:
#   Writes a "<attr>: key=value ..." line to stdout.
#######################################
stats_for() {
  local attr="$1"
  local stats
  stats="$(NIX_SHOW_STATS=1 nix eval --raw --file "${FIRN_ROOT}/nix/pkgs.nix" \
    "${attr}" 2>&1 >/dev/null)"
  printf '%s\n' "${stats}" | jq -r --arg attr "${attr}" \
    '"\($attr): nrThunks=\(.nrThunks) nrFunctionCalls=\(.nrFunctionCalls) nrExprs=\(.nrExprs) cpuTime=\(.cpuTime)"'
}

stats_for hello.name
stats_for hello.outPath
total="$(nix eval --impure --expr "${attrs_expr}")"
echo "top-level attributes: ${total}"
echo "attributes forced: 1 of ${total} ($(awk -v t="${total}" 'BEGIN { printf "%.4f", 100 / t }')%)"
echo "== only the attribute names (no package forced)"
NIX_SHOW_STATS=1 nix eval --impure --expr "${attrs_expr}" 2>&1 >/dev/null \
  | jq -r '"names only: nrThunks=\(.nrThunks) nrFunctionCalls=\(.nrFunctionCalls) cpuTime=\(.cpuTime)"'
