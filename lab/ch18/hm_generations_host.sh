#!/usr/bin/env bash
#
# Reads the build log of the home-vm check (nixos/tests/home.nix) and shows the
# two `home-manager generations` results the test script printed: empty when
# Home Manager runs as a NixOS module, one generation once the activation
# package is registered in the home-manager profile the way a standalone
# `home-manager switch` does. Builds the check first if it is not in the store.
# Host only: needs /dev/kvm.

set -o errexit
set -o nounset
set -o pipefail

readonly ATTR="${FIRN_ROOT}#checks.x86_64-linux.home-vm"

main() {
  nix build --no-link "${ATTR}"
  local lines
  lines="$(nix log "${ATTR}" | grep -o 'firn: hm_generations.*' | sed -E 's|/nix/store/[a-z0-9]{32}-|/nix/store/<hash>-|')"
  if [[ -z "${lines}" ]]; then
    echo "no hm_generations lines in the build log" >&2
    return 1
  fi
  printf '%s\n' "${lines}"
}

main "$@"
