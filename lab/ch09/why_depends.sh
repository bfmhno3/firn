#!/usr/bin/env bash
#
# Why is that path in my closure? `nix why-depends` answers with a chain of
# references. Here: mini.hello references greeting (through its text) and
# the static busybox; the output paths are fixed for the pinned nixpkgs. Then
# the same question at build time (--derivation): which inputs does the
# .drv of mini.hello name?

set -o errexit
set -o nounset
set -o pipefail

system="$(nix eval --raw --impure --expr builtins.currentSystem)"
readonly system
readonly mini="${FIRN_ROOT}#legacyPackages.${system}.mini"

echo "== nix why-depends mini.hello mini.greeting"
nix why-depends "${mini}.hello" "${mini}.greeting" 2>/dev/null \
  | sed 's|/nix/store/[a-z0-9]*-|/nix/store/<hash>-|g; s/\x1b\[[0-9;]*m//g'

echo
echo "== nix why-depends --derivation mini.hello mini.busybox"
nix why-depends --derivation "${mini}.hello" "${mini}.busybox" 2>/dev/null \
  | sed 's|/nix/store/[a-z0-9]*-|/nix/store/<hash>-|g; s/\x1b\[[0-9;]*m//g'

echo
echo "== nix-store -qR (closure of the built output)"
nix-build "${FIRN_ROOT}" -A mini.hello --no-out-link \
  | xargs nix-store -qR | sed 's|/nix/store/[a-z0-9]*-|/nix/store/<hash>-|'
