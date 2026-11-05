#!/usr/bin/env bash
#
# `nix run` in its two forms: a flake app (`.#mini-hello`, program taken from
# the flake's `apps` output) and a plain nixpkgs attribute through the
# legacy entry point (`-f nix/pkgs.nix hello`, program taken from
# `meta.mainProgram` or the package name).

set -o errexit
set -o nounset
set -o pipefail

echo "== nix run .#mini-hello"
nix run "${FIRN_ROOT}#mini-hello"

echo
echo "== nix run -f nix/pkgs.nix hello"
nix run -f "${FIRN_ROOT}/nix/pkgs.nix" hello
