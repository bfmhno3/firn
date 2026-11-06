#!/usr/bin/env bash
#
# Builds system.build.toplevel of nixosConfigurations.lab, lists the result
# (the whole system as one store path of symlinks) and prints its closure
# size and path count. The numbers are fixed by the pin.

set -o errexit
set -o nounset
set -o pipefail

main() {
  local top
  top="$(nix build "${FIRN_ROOT}#nixosConfigurations.lab.config.system.build.toplevel" \
    --no-link --print-out-paths)"
  echo "== ls of the toplevel"
  ls "${top}"
  echo
  echo "== nixos-version"
  cat "${top}/nixos-version"
  echo
  echo
  echo "== closure"
  nix path-info -S "${top}" | awk '{ printf "closure size: %d bytes\n", $2 }'
  echo "closure paths: $(nix path-info -r "${top}" | wc -l)"
}

main "$@"
