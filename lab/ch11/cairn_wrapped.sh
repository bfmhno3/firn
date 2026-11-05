#!/usr/bin/env bash
#
# `bin/cairn` in the package is a wrapper made by makeWrapper; the real script
# was renamed to `.cairn-wrapped` and its shebang points into the store.
# Then a snapshot of a tiny tree with a fixed CAIRN_NOW is made and verified
# with the packaged binary only, nothing from the host.

set -o errexit
set -o nounset
set -o pipefail

out="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#cairn")"

echo "== head of bin/cairn (the wrapper)"
head -n 12 "${out}/bin/cairn"

echo
echo "== shebang of .cairn-wrapped"
head -n 1 "${out}/bin/.cairn-wrapped"

echo
echo "== snapshot and verify with CAIRN_NOW=20261102T000000Z"
export HOME="${LAB_TMP}"
mkdir -p "${LAB_TMP}/src"
echo hello >"${LAB_TMP}/src/a.txt"
echo world >"${LAB_TMP}/src/b.txt"
cat >"${LAB_TMP}/cairn.conf" <<CONF
repo = ${LAB_TMP}/repo
source = ${LAB_TMP}/src
CONF
"${out}/bin/cairn" -c "${LAB_TMP}/cairn.conf" init "${LAB_TMP}/repo"
CAIRN_NOW=20261102T000000Z "${out}/bin/cairn" -c "${LAB_TMP}/cairn.conf" snapshot
"${out}/bin/cairn" -c "${LAB_TMP}/cairn.conf" verify
