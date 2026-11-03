#!/usr/bin/env bash
#
# Where is the real C++ stack wall? With max-call-depth raised to one million,
# naive sumTo only fails when the process runs out of stack. Prints a fixed
# probe table, then a bounded bisect over multiples of 100 between 25000 and
# 30000 that reports the first failing depth, then the same probes under
# `ulimit -s 65536`. The numbers depend on the stack size (8192 KiB here).

set -o errexit
set -o nounset
set -o pipefail

readonly sum_to='let sumTo = n: if n == 0 then 0 else n + sumTo (n - 1); in sumTo'

#######################################
# Evaluate sumTo N with max-call-depth raised; print the last result or error.
# Arguments:
#   N.
# Outputs:
#   Writes the number, or the last "error: ..." line, to stdout.
#######################################
probe() {
  nix eval --option max-call-depth 1000000 --expr "${sum_to} $1" 2>&1 \
    | grep -E '^[0-9]+$|error: ' | sed 's/^ *//' | tail -n 1 || true
}

#######################################
# Succeeds when sumTo N evaluates to a number.
# Arguments:
#   N.
#######################################
passes() {
  [[ "$(probe "$1")" =~ ^[0-9]+$ ]]
}

for n in 25000 28000 29000 29100 29200 30000; do
  printf '%s: %s\n' "${n}" "$(probe "${n}")"
done

# 不变式：lo 通过，hi 失败；每次把区间缩小一半，单位是 100 层。
lo=25000
hi=30000
while ((hi - lo > 100)); do
  mid=$(((lo + hi) / 2))
  mid=$((mid - mid % 100))
  if passes "${mid}"; then
    lo="${mid}"
  else
    hi="${mid}"
  fi
done
echo "first failing depth (100-step bisect): ${hi}"
echo "stack limit: $(ulimit -s) KiB"

for lim in 8192 65536; do
  for n in 29200 200000; do
    printf 'ulimit -s %s, depth %s: %s\n' "${lim}" "${n}" \
      "$( (ulimit -s "${lim}" && probe "${n}"))"
  done
done
