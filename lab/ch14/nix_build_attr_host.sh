#!/usr/bin/env bash
#
# Builds the contributed package inside the nixpkgs worktree the way a
# reviewer would: nix-build -A cairn (runs the 81 bats tests of checkPhase)
# and nix-build -A cairn.tests.version (passthru.tests.version, which runs
# `cairn --version` and looks for the version in its output). Host only.

set -o errexit
set -o nounset
set -o pipefail

FIRN_NIXPKGS="${FIRN_NIXPKGS:-${HOME}/.cache/firn/nixpkgs}"
export FIRN_NIXPKGS
bash "${FIRN_ROOT}/scripts/nixpkgs-worktree.sh" >/dev/null 2>&1
cd "${FIRN_NIXPKGS}"

echo "== nix-build -A cairn"
start="$(date +%s%N)"
out="$(nix-build -A cairn --no-out-link 2>/dev/null)"
end="$(date +%s%N)"
echo "volatile: wall time $(((end - start) / 1000000)) ms"
echo "volatile: ${out}"
"${out}/bin/cairn" --version

echo
echo "== nix-build -A cairn.tests.version"
start="$(date +%s%N)"
test_out="$(nix-build -A cairn.tests.version --no-out-link 2>/dev/null)"
end="$(date +%s%N)"
echo "volatile: wall time $(((end - start) / 1000000)) ms"
echo "volatile: ${test_out}"
cat "${test_out}"
