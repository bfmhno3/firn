#!/usr/bin/env bash
#
# Evaluator statistics (NIX_SHOW_STATS=1) of the same sum: naive recursion vs
# foldl'. Both add 1..9000 (the naive version cannot go deeper, see
# call_depth_limit.sh); foldl' is also run on 1..1000000. Timings are the
# median of 5 runs.

set -o errexit
set -o nounset
set -o pipefail

readonly naive='let sumTo = n: if n == 0 then 0 else n + sumTo (n - 1); in sumTo 9000'
readonly fold9k="builtins.foldl' builtins.add 0 (builtins.genList (i: i + 1) 9000)"
readonly fold1m="builtins.foldl' builtins.add 0 (builtins.genList (i: i + 1) 1000000)"

#######################################
# Print the statistics of one expression.
# Arguments:
#   Label, Nix expression.
# Outputs:
#   Writes one "<label>: ..." line to stdout.
#######################################
stats_for() {
  local label="$1"
  NIX_SHOW_STATS=1 nix eval --expr "$2" 2>&1 >/dev/null \
    | jq -r --arg label "${label}" \
      '"\($label): nrThunks=\(.nrThunks) nrFunctionCalls=\(.nrFunctionCalls) envs=\(.envs.number) heapSize=\(.gc.heapSize) totalBytes=\(.gc.totalBytes)"'
}

#######################################
# Median wall time of 5 runs in milliseconds.
# Arguments:
#   Nix expression.
# Outputs:
#   Writes the median to stdout.
#######################################
median_ms() {
  local start end
  local -a times=()
  for _ in 1 2 3 4 5; do
    start="${EPOCHREALTIME/./}"
    nix eval --expr "$1" >/dev/null
    end="${EPOCHREALTIME/./}"
    times+=($(((end - start) / 1000)))
  done
  printf '%s\n' "${times[@]}" | sort -n | sed -n 3p
}

stats_for "naive 1..9000      " "${naive}"
stats_for "foldl' 1..9000     " "${fold9k}"
stats_for "foldl' 1..1000000  " "${fold1m}"
echo "median ms: naive 9000 = $(median_ms "${naive}")," \
  "foldl' 9000 = $(median_ms "${fold9k}")," \
  "foldl' 1000000 = $(median_ms "${fold1m}")"
