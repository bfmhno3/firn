#!/usr/bin/env bash
#
# Shows what services.cairn generates inside the toplevel: /etc/cairn/cairn.conf
# (the rendered configText) and the unit file of cairn.service and cairn.timer,
# both reached through the etc/ symlink of the system.

set -o errexit
set -o nounset
set -o pipefail

main() {
  local top
  top="$(nix build "${FIRN_ROOT}#nixosConfigurations.lab.config.system.build.toplevel" \
    --no-link --print-out-paths)"
  echo "== etc/cairn/cairn.conf is a link"
  readlink "${top}/etc/cairn/cairn.conf" | sed 's|^/nix/store/[a-z0-9]*-||'
  echo
  echo "== cat etc/cairn/cairn.conf"
  cat "${top}/etc/cairn/cairn.conf"
  echo
  echo "== cat etc/systemd/system/cairn.service"
  sed 's|/nix/store/[a-z0-9]*-|/nix/store/<hash>-|g' \
    "${top}/etc/systemd/system/cairn.service"
  echo
  echo "== cat etc/systemd/system/cairn.timer"
  cat "${top}/etc/systemd/system/cairn.timer"
}

main "$@"
