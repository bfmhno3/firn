#!/usr/bin/env bash
#
# `nix log` of the mini hello: the "== phase <name>" lines setup.sh prints
# before each phase. The build runs first (a no-op when it is already built);
# nix log reads the log of the .drv.

set -o errexit
set -o nounset
set -o pipefail

system="$(nix eval --raw --impure --expr builtins.currentSystem)"
readonly system
readonly hello="${FIRN_ROOT}#legacyPackages.${system}.mini.hello"

nix build --no-link "${hello}"
nix log "${hello}"
