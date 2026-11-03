#!/usr/bin/env bash
#
# Times naive fib 25 against the shared (memoized list) fib 80 and fib 25.
# Prints the median of 5 runs in ms for each; asserts nothing about speed.

set -o errexit
set -o nounset
set -o pipefail

readonly naive='let fib = n: if n < 2 then n else fib (n - 1) + fib (n - 2); in fib 25'
readonly memo_tmpl='let memo = builtins.genList (n: if n < 2 then n else builtins.elemAt memo (n - 1) + builtins.elemAt memo (n - 2)) 81; in builtins.elemAt memo'

#######################################
# Print the median wall time in ms of 5 `nix eval --expr` runs.
# Arguments:
#   Nix expression.
# Outputs:
#   Writes the median in ms to stdout.
#######################################
median_ms() {
  local expr="$1"
  local start end
  local -a times=()
  while ((${#times[@]} < 5)); do
    start="${EPOCHREALTIME/./}"
    nix eval --expr "${expr}" >/dev/null
    end="${EPOCHREALTIME/./}"
    times+=("$(((end - start) / 1000))")
  done
  printf '%s\n' "${times[@]}" | sort -n | sed -n 3p
}

naive_ms="$(median_ms "${naive}")"
memo25_ms="$(median_ms "${memo_tmpl} 25")"
memo80_ms="$(median_ms "${memo_tmpl} 80")"
echo "naive fib 25:  ${naive_ms} ms"
echo "shared fib 25: ${memo25_ms} ms"
echo "shared fib 80: ${memo80_ms} ms"
echo "ratio naive/shared fib 25: $(awk -v a="${naive_ms}" -v b="${memo25_ms}" 'BEGIN { printf "%.1f", a / b }')"
