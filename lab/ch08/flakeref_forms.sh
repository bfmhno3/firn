#!/usr/bin/env bash
#
# Four flake reference forms through `nix flake metadata`: github: with a
# pinned revision, path:, git+file://, and the indirect `nixpkgs` resolved
# through a registry. The registry is a private file under LAB_TMP passed with
# --flake-registry, so the host's registries are only read, never changed.

set -o errexit
set -o nounset
set -o pipefail

lock="${FIRN_ROOT}/flake.lock"
rev="$(jq -r '.nodes.nixpkgs.locked.rev' "${lock}")"
readonly rev
readonly nixpkgs_ref="github:NixOS/nixpkgs/${rev}"

#######################################
# Print selected lines of `nix flake metadata` for a reference.
# Arguments:
#   Flake reference, then extra nix arguments.
#######################################
meta() {
  local ref="$1"
  shift
  local args="$*"
  echo "\$ nix flake metadata ${ref} ${args//${LAB_TMP}/\$LAB_TMP}"
  # `nix flake metadata` bolds its labels even when piped; strip the escapes.
  nix flake metadata "$@" "${ref}" \
    | sed -E 's/\x1b\[[0-9;]*m//g' \
    | grep -E '^(Resolved URL|Locked URL|Description|Path|Revision|Last modified)' \
    | sed -E 's|/nix/store/[0-9a-z]{32}-|/nix/store/<hash>-|'
  echo
}

echo '== github:OWNER/REPO/REV'
meta "${nixpkgs_ref}"

echo '== path:'
meta "path:${FIRN_ROOT}"

echo '== git+file://'
meta "git+file://${FIRN_ROOT}"

echo '== indirect: nixpkgs, resolved by a registry'
# Private registries: a global registry file with two entries, and a user
# registry under LAB_TMP (the user registry beats the system and global ones).
jq -n '{
  version: 2,
  flakes: [
    { from: { type: "indirect", id: "flake-utils" },
      to: { type: "github", owner: "numtide", repo: "flake-utils" } },
    { from: { type: "indirect", id: "home-manager" },
      to: { type: "github", owner: "nix-community", repo: "home-manager" } }
  ]
}' >"${LAB_TMP}/registry.json"
export XDG_CONFIG_HOME="${LAB_TMP}/config"
echo "\$ nix registry add nixpkgs ${nixpkgs_ref}"
nix registry add --flake-registry "${LAB_TMP}/registry.json" \
  nixpkgs "${nixpkgs_ref}"
echo
echo "\$ nix registry list | sed -n 1,5p"
nix registry list --flake-registry "${LAB_TMP}/registry.json" \
  | sed -n '1,5p' | sed -E 's|/nix/store/[0-9a-z]{32}-|/nix/store/<hash>-|'
echo
meta nixpkgs --flake-registry "${LAB_TMP}/registry.json"
