#!/usr/bin/env bash
#
# Runs statix and deadnix on fixtures/smelly.nix, a file with deliberate
# problems, and counts what each tool reports (statix: one warning per lint,
# so repeated keys count once; deadnix: one finding per unused name). statix
# check exits 1 when it finds anything and deadnix without --fail always exits
# 0; the lab only reports the counts and fails if a tool finds nothing (that
# would mean the fixture or the tool changed).

set -o errexit
set -o nounset
set -o pipefail

main() {
  local file="${FIRN_ROOT}/lab/ch20/fixtures/smelly.nix"
  local statix_json deadnix_json

  echo "== statix check"
  statix check "${file}" 2>&1 | sed "s|${FIRN_ROOT}/||" || true
  statix_json="$(statix check --format json "${file}" || true)"

  echo "== deadnix"
  deadnix "${file}" 2>&1 | sed "s|${FIRN_ROOT}/||" || true
  deadnix_json="$(deadnix --output-format json "${file}")"

  local statix_count deadnix_count
  statix_count="$(jq '.report | length' <<<"${statix_json}")"
  deadnix_count="$(jq '[.results[]] | length' <<<"${deadnix_json}")"
  echo "statix warnings: ${statix_count}"
  echo "deadnix findings: ${deadnix_count}"
  ((statix_count > 0 && deadnix_count > 0))
}

main "$@"
