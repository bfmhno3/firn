#!/usr/bin/env bash
#
# A "secret" written with writeText lands in the Nix store as a file with mode
# 444: every local user can read it, and it stays there until garbage
# collection. The store path itself depends on the content only (no secret
# is needed to find it), so it is not worth hiding either.

set -o errexit
set -o nounset
set -o pipefail

main() {
  local out
  # BAD: a secret passed through the store.
  out="$(nix build --impure --no-link --print-out-paths --expr "
    let pkgs = import ${FIRN_ROOT}/nix/pkgs.nix { };
    in pkgs.writeText \"firn-secret\" \"hunter2-firn-lab\"
  ")"
  echo "mode:  $(stat -c %a "${out}")"
  echo "owner: $(stat -c %U:%G "${out}")"
  echo "read as another user would: $(cat "${out}")"
  [[ "$(stat -c %a "${out}")" == 444 ]] || {
    echo "expected mode 444" >&2
    return 1
  }
}

main "$@"
