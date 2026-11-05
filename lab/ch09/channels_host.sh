#!/usr/bin/env bash
#
# Host only. Channels are the legacy way to say what `<nixpkgs>` means. The
# lookup path NIX_PATH decides it, and NIX_PATH comes from the environment of
# whoever runs Nix: that is the impurity. This prints the channel list, the
# NIX_PATH of this shell, and what `nix-instantiate --find-file nixpkgs`
# resolves it to. All three differ from machine to machine.

set -o errexit
set -o nounset
set -o pipefail

echo "volatile: == nix-channel --list"
nix-channel --list
echo "(end of list)"

echo
echo "volatile: == NIX_PATH"
echo "${NIX_PATH:-unset}"

echo
echo "volatile: == nix-instantiate --find-file nixpkgs"
nix-instantiate --find-file nixpkgs 2>&1 || true
