#!/usr/bin/env bash
#
# Shared by the template and direnv labs: pin the nixpkgs input of a template
# project to the source firn itself uses. The template's flake.nix says
# github:NixOS/nixpkgs/nixos-unstable. A `github:` override with rev and
# narHash still contacted github in a full `make ci` run (the first lock took
# 20.8 s and a later one failed with the network unreachable), so the lock
# points at the store path of nix/pins.nix instead: its narHash equals the one
# in flake.lock and `nix --offline flake lock` takes under 0.1 s. Sourced, not
# executed.

#######################################
# Write flake.lock in the current directory with nixpkgs from nix/pins.nix.
# Globals:
#   FIRN_ROOT
# Returns:
#   Non-zero if the lock cannot be written.
#######################################
pin_nixpkgs::lock() {
  local source nar_hash
  source="$(nix eval --raw --file "${FIRN_ROOT}/nix/pins.nix" nixpkgs \
    2>/dev/null)" || return 1
  nar_hash="$(jq -r '.nodes.nixpkgs.locked.narHash' \
    "${FIRN_ROOT}/flake.lock")" || return 1
  nix --offline flake lock --override-input nixpkgs \
    "path:${source}?narHash=${nar_hash}" 2>/dev/null
}
