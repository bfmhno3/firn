#!/usr/bin/env bash
#
# An error three calls deep in Firn lib: pipe -> mapAttrsToList -> the
# user's function -> `1 + "s"`. The default error message shows the last
# frames; --show-trace shows every frame. The lab prints both excerpts and
# exits with nix's own (non-zero) status.

set -o errexit
set -o nounset
set -o pipefail

readonly expr='let lib = import '"${FIRN_ROOT}"'/lib; in lib.pipe { a = { x = 1; }; } [ (lib.mapAttrsToList (_: v: lib.attrByPath [ "x" ] 0 v + "s")) ]'

status=0
plain="$(nix eval --impure --json --expr "${expr}" 2>&1)" || status=$?
traced="$(nix eval --impure --json --show-trace --expr "${expr}" 2>&1)" || true

echo "== without --show-trace: ${status}, $(printf '%s\n' "${plain}" | wc -l) lines"
printf '%s\n' "${plain}" | sed "s|${FIRN_ROOT}|\$FIRN_ROOT|g" | head -n 14
echo "== with --show-trace: $(printf '%s\n' "${traced}" | wc -l) lines"
printf '%s\n' "${traced}" | sed "s|${FIRN_ROOT}|\$FIRN_ROOT|g" | grep -E "while|error:|at [$]FIRN_ROOT" | head -n 20
exit "${status}"
