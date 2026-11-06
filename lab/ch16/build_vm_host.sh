#!/usr/bin/env bash
#
# Builds config.system.build.vm of nixosConfigurations.lab (the same thing
# `nixos-rebuild build-vm` builds), prints the run script and the closure
# size. The VM is not booted. Host only: the build pulls a kernel and a
# disk-less system closure.

set -o errexit
set -o nounset
set -o pipefail

main() {
  local vm
  vm="$(nix build "${FIRN_ROOT}#nixosConfigurations.lab.config.system.build.vm" \
    --no-link --print-out-paths)"
  echo "== bin/ of the vm output"
  ls "${vm}/bin"
  echo
  echo "== run script"
  echo "${vm}/bin/run-"*"-vm" | sed 's|/nix/store/[a-z0-9]*-|/nix/store/<hash>-|'
  echo
  echo "== closure"
  nix path-info -S "${vm}" | awk '{ printf "closure size: %d bytes\n", $2 }'
  echo "closure paths: $(nix path-info -r "${vm}" | wc -l)"
}

main "$@"
