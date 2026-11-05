#!/usr/bin/env bash
#
# Four ways to change firn-hello and what each does to the out path and the
# name. `override` changes an argument of package.nix (greeting) and keeps the
# name. `overrideAttrs` changes the attributes handed to mkDerivation; because
# package.nix uses `finalAttrs`, bumping `version` makes `name` follow.
# `lib.overrideDerivation` (deprecated) changes the final derivation
# arguments, after `name` was already computed, so `name` does not follow.
# A fixture shows the same effect for `rec` versus `finalAttrs`. Every out
# path here is derived from the pinned nixpkgs, so the hashes stay the same
# on any machine with the same pin. Builds go to the store, no result links.

set -o errexit
set -o nounset
set -o pipefail

fixtures="${FIRN_ROOT}/lab/ch10/fixtures"
readonly fixtures

echo "== out path and name per variant"
for v in base overridden bumped rebuilt legacy; do
  out="$(nix eval --raw --file "${fixtures}/overrides.nix" "${v}.outPath")"
  name="$(nix eval --raw --file "${fixtures}/overrides.nix" "${v}.name")"
  printf '%-10s %s\n' "${v}" "${out}"
  printf '%-10s name = %s\n' "" "${name}"
done

echo
echo "== firn-hello-hallo of the flake is the same derivation as override { greeting = \"Hallo\"; }"
system="$(nix eval --raw --impure --expr builtins.currentSystem)"
readonly system
flake_hallo="$(nix eval --raw "${FIRN_ROOT}#packages.${system}.firn-hello-hallo.outPath")"
overridden="$(nix eval --raw --file "${fixtures}/overrides.nix" overridden.outPath)"
if [[ "${flake_hallo}" == "${overridden}" ]]; then
  echo "same out path"
else
  echo "DIFFERENT out paths"
  exit 1
fi

echo
echo "== run base and overridden"
base="$(nix build --no-link --print-out-paths -f "${FIRN_ROOT}/nix/pkgs.nix" firn-hello)"
readonly base
"${base}/bin/firn-hello" nix
built="$(nix build --no-link --print-out-paths -f "${fixtures}/overrides.nix" overridden)"
readonly built
"${built}/bin/firn-hello" nix

echo
echo "== overrideAttrs without __intentionallyOverridingVersion: eval warning"
# shellcheck disable=SC2016  # the backticks are literal text of the warning
nix eval --raw --file "${fixtures}/overrides.nix" bumpedNoisy.name 2>&1 >/dev/null \
  | sed -n 's/^\(evaluation warning: [^ ]* was overridden with `version` but not `src`\) at .*/\1/p'

echo
echo "== rec versus finalAttrs, after overrideAttrs (_: { version = \"2\"; })"
nix eval --file "${fixtures}/rec_vs_final.nix"
