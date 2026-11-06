#!/usr/bin/env bash
#
# The c template end to end, inside LAB_TMP: list the templates of this flake,
# `nix flake init -t "${FIRN_ROOT}#c"` (its welcomeText is printed by nix),
# `git init && git add -A` (flakes only see tracked files), build, and run
# the binary. The template's flake.nix says github:NixOS/nixpkgs/nixos-unstable;
# the lab overrides that input with the revision and hash from firn's own
# flake.lock, so nothing is downloaded and the result matches the rest of the
# series. Build output paths are volatile.

set -o errexit
set -o nounset
set -o pipefail

readonly LOCK="${FIRN_ROOT}/flake.lock"

main() {
  local rev nar_hash
  rev="$(jq -r '.nodes.nixpkgs.locked.rev' "${LOCK}")"
  nar_hash="$(jq -r '.nodes.nixpkgs.locked.narHash' "${LOCK}")"

  echo "== templates of the firn flake"
  nix eval --json "${FIRN_ROOT}#templates" \
    --apply 'ts: builtins.mapAttrs (_: t: t.description) ts' | jq .

  echo
  echo "== nix flake init -t firn#c"
  mkdir "${LAB_TMP}/hello-c"
  cd "${LAB_TMP}/hello-c"
  nix flake init -t "${FIRN_ROOT}#c" 2>&1 \
    | grep -v "^warning" | sed "s|${LAB_TMP}|\$LAB_TMP|"
  git init -q
  git add -A
  find . -path ./.git -prune -o -type f -print | LC_ALL=C sort

  echo
  echo "== nix build"
  nix flake lock --override-input nixpkgs \
    "github:NixOS/nixpkgs/${rev}?narHash=${nar_hash}" 2>/dev/null
  git add -A
  local out
  out="$(nix build --no-link --print-out-paths 2>/dev/null)"
  printf 'volatile: %s\n' "${out}"
  "${out}/bin/hello-c"

  echo
  echo "== nix run"
  nix run 2>/dev/null
}

main "$@"
