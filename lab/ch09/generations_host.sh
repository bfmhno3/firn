#!/usr/bin/env bash
#
# Host only. NixOS generations are profile generations too: the system profile
# at /nix/var/nix/profiles/system is a symlink chain system-<N>-link. This
# lists the newest three links, then compares the last two generations with
# `nvd diff` and with `nix store diff-closures`. Read-only; the output is
# whatever this machine has, so every line is volatile. Only the first lines
# of each diff are shown, and the host name in the system path
# (`nixos-system-<host>-<version>`) is masked as <host>.

set -o errexit
set -o nounset
set -o pipefail

readonly profiles=/nix/var/nix/profiles

#######################################
# Replace the host name in `nixos-system-<host>[-<version>]` with <host>.
#######################################
mask_host() {
  sed -e 's/nixos-system-[a-z0-9-]*-\([0-9][0-9]\.[0-9][0-9]\.\)/nixos-system-<host>-\1/g' \
    -e 's/nixos-system-[a-z0-9-]*\( *[0-9]\)/nixos-system-<host>\1/g'
}

echo "volatile: == ls -l ${profiles} | grep system | tail -3"
# shellcheck disable=SC2010  # `ls -l` shows the links, as the post does
ls -l "${profiles}" | grep system | tail -n 3 | awk '{print $6, $7, $8, $9, $10, $11}' | mask_host

mapfile -t links < <(
  find "${profiles}" -maxdepth 1 -name 'system-*-link' \
    | sort -t- -k2,2n | tail -n 2
)
readonly links
old="$(readlink -f "${links[0]}")"
new="$(readlink -f "${links[1]}")"
readonly old new

echo
echo "volatile: == nvd diff ${links[0]##*/} ${links[1]##*/}"
nvd --color never diff "${old}" "${new}" | mask_host | sed -n '1,5p'

echo
echo "volatile: == nix store diff-closures ${links[0]##*/} ${links[1]##*/}"
nix store diff-closures "${old}" "${new}" | mask_host | sed -n '1,5p'
