#!/usr/bin/env bash
#
# `nix log` of the mini hello: the "== phase <name>" lines setup.sh prints
# before each phase. The build runs first (a no-op when it is already built),
# then once more with --rebuild: a path that was substituted from a binary
# cache (as in CI with the Cachix cache) has no build log, and the rebuild
# (the output is reproducible) makes Nix run the builder and keep one.
# nix log reads the log of the .drv.

set -o errexit
set -o nounset
set -o pipefail

system="$(nix eval --raw --impure --expr builtins.currentSystem)"
readonly system
readonly hello="${FIRN_ROOT}#legacyPackages.${system}.mini.hello"

nix build --no-link "${hello}"
nix build --no-link --rebuild "${hello}"
nix log "${hello}"
