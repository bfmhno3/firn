#!/usr/bin/env bash
#
# The three faces of Nix on this machine: language, store, operating system.

set -o errexit
set -o nounset
set -o pipefail

echo '== language'
nix eval --expr '1 + 1'
echo '== store'
nix path-info -Sh /run/current-system
printf 'paths in closure: '
nix-store -qR /run/current-system | wc -l
echo '== operating system'
readlink /run/current-system
nixos-version
