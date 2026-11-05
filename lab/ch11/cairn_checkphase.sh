#!/usr/bin/env bash
#
# checkPhase runs before installPhase against the source tree, so the test
# suite of cairn is part of the build. Its bats summary is in the build log.
# `nix log` has the log only when this machine built cairn; a substituted
# build has none, then `--rebuild` rebuilds it once to produce one.

set -o errexit
set -o nounset
set -o pipefail

installable="${FIRN_ROOT}#cairn"
nix build --no-link "${installable}"

log="${LAB_TMP}/cairn.log"
if ! nix log "${installable}" >"${log}" 2>/dev/null; then
  echo "volatile: no local build log, rebuilding with --rebuild"
  nix build --no-link --rebuild -L "${installable}" >"${log}" 2>&1
fi

grep -E 'Running phase: (checkPhase|installPhase|installCheckPhase)' "${log}"
grep -E '^(cairn> )?[0-9]+ tests, [0-9]+ failures' "${log}" | sed 's/^cairn> //'
