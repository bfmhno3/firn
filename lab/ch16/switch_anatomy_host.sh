#!/usr/bin/env bash
#
# Looks, read-only, at the NixOS system the shell runs on: what
# switch-to-configuration is, which system generations exist, the version
# string and the contents of /run/current-system. Changes nothing. Host only,
# and every line of output depends on the machine.

set -o errexit
set -o nounset
set -o pipefail

#######################################
# Run a command and prefix its output lines with `volatile: `.
# Arguments:
#   Shell snippet to run.
#######################################
show() {
  echo "== $1"
  bash -c "$1" 2>&1 | sed 's/^/volatile: /'
  echo
}

main() {
  show 'file /run/current-system/bin/switch-to-configuration'
  show 'ls -l /nix/var/nix/profiles | grep system | tail -3'
  show 'cat /run/current-system/nixos-version'
  show 'ls /run/current-system'
}

main "$@"
