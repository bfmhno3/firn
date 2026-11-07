#!/usr/bin/env bash
#
# A secret in a derivation attribute becomes an environment variable of the
# builder, and the environment is stored in the .drv file. The .drv is a store
# file too (mode 444), so it leaks even if the build output never mentions the
# secret. `nix derivation show` makes it easy to see.

set -o errexit
set -o nounset
set -o pipefail

main() {
  local drv
  # BAD: the token is an attribute of the derivation.
  drv="$(nix-instantiate --expr "
    let pkgs = import ${FIRN_ROOT}/nix/pkgs.nix { };
    in pkgs.runCommand \"firn-drv-secret\" { API_TOKEN = \"hunter2-firn-lab\"; } \"touch \$out\"
  " 2>/dev/null)"
  echo "drv mode: $(stat -c %a "${drv}")"
  echo "== nix derivation show | grep"
  nix derivation show "${drv}" | grep -o '"API_TOKEN":"[^"]*"' || {
    echo "secret not found in the .drv" >&2
    return 1
  }
}

main "$@"
