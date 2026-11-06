#!/usr/bin/env bash
#
# Exercise answer: why `config = if cfg.enable then { … } else { }` recurses
# and `config = mkIf cfg.enable { … }` does not. Both fixtures define the
# same module; only the shape of `config` differs. The first run must fail
# with infinite recursion, the second must print "on".

set -o errexit
set -o nounset
set -o pipefail

readonly FIXTURES="${FIRN_ROOT}/lab/ch15/fixtures"

echo '== if/else around config (BAD)'
status=0
err="$(nix eval --file "${FIXTURES}/mkif_bad.nix" 2>&1)" || status=$?
printf '%s\n' "${err}" | grep -E 'error: infinite recursion' || true
echo "exit: ${status}"
if ((status == 0)); then
  echo 'expected the if/else version to recurse' >&2
  exit 1
fi

echo '== mkIf'
nix eval --file "${FIXTURES}/mkif_good.nix"
