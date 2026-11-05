#!/usr/bin/env bash
#
# Exercise answer: pin a profile entry to one exact store path and roll back.
# `nix profile add /nix/store/...-hello-2.12.3` installs that store path as it
# is, with no attribute and no nixpkgs behind it, so `nix profile
# upgrade` has nothing to move it to (it warns and leaves it alone). Then a second add and a rollback show
# that the pinned entry survives in the older generation. All in LAB_TMP.

set -o errexit
set -o nounset
set -o pipefail

readonly prof="${LAB_TMP}/pinned"

hello="$(nix-build "${FIRN_ROOT}/nix/pkgs.nix" -A hello --no-out-link)"
readonly hello

echo "== pin hello by store path"
nix profile add --profile "${prof}" "${hello}" 2>/dev/null
nix profile list --profile "${prof}" | sed 's/\x1b\[[0-9;]*m//g' | grep -E '^(Name|Original flake URL|Store paths)'

echo
echo "== nix profile upgrade --all"
nix profile upgrade --profile "${prof}" --all 2>&1 | sed 's/^warning: //'

echo
echo "== add jq by attribute (generation 2)"
nix profile add --profile "${prof}" -f "${FIRN_ROOT}/nix/pkgs.nix" jq 2>/dev/null
nix profile list --profile "${prof}" | sed 's/\x1b\[[0-9;]*m//g' | grep -E '^Name'

echo
echo "== rollback"
nix profile rollback --profile "${prof}" 2>&1
nix profile list --profile "${prof}" | sed 's/\x1b\[[0-9;]*m//g' | grep -E '^Name'
echo "pinned path still the one in the profile: $(test "$(readlink -f "${prof}/bin/hello")" = "$(readlink -f "${hello}/bin/hello")" && echo yes || echo no)"
