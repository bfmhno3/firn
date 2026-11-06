#!/usr/bin/env bash
#
# Reads three values out of nixosConfigurations.lab with `nix eval`, without
# building anything: an option of services.cairn, the ExecStart the module
# turned it into, and the timer settings.

set -o errexit
set -o nounset
set -o pipefail

readonly LAB="${FIRN_ROOT}#nixosConfigurations.lab.config"

main() {
  echo "== services.cairn.settings.cairn.sources"
  nix eval --json "${LAB}.services.cairn.settings.cairn.sources"
  echo
  echo "== systemd.services.cairn.serviceConfig.ExecStart"
  nix eval --raw "${LAB}.systemd.services.cairn.serviceConfig.ExecStart" \
    | sed 's|/nix/store/[a-z0-9]*-|/nix/store/<hash>-|'
  echo
  echo
  echo "== systemd.timers.cairn.timerConfig"
  nix eval --json "${LAB}.systemd.timers.cairn.timerConfig"
}

main "$@"
