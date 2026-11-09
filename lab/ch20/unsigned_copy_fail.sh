#!/usr/bin/env bash
#
# The same copy as local_cache.sh, but the lab key is not in
# trusted-public-keys. The cache is signed, the signature is valid, and Nix
# still refuses: a signature only counts when its key is trusted. The copy
# fails with "lacks a signature by a trusted key".
#
# The copied path is built here from a fresh nonce, so no cache can have signed
# it: firn-hello would not do, because in CI it is substituted from the Cachix
# cache, whose key the runner trusts, and the copy would succeed. The trusted
# keys and require-sigs are also set explicitly (cache.nixos.org only) instead
# of coming from the ambient nix.conf; the ambient values are printed first.

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=/dev/null
source "${FIRN_ROOT}/lab/ch20/fixtures/make_cache.sh"

main() {
  # shellcheck disable=SC2034 # read by make_cache, sourced above
  FIRN_LAB_SUBJECT="$(nix build --no-link --print-out-paths --impure --expr \
    "(import ${FIRN_ROOT}/nix/pkgs.nix { }).runCommand \"firn-lab-unsigned\" \
      { nonce = \"$(date +%s%N)\"; } \"echo \$nonce > \$out\"")"
  make_cache
  echo "volatile: ambient require-sigs: $(nix config show require-sigs)"
  echo "volatile: ambient trusted-users: $(nix config show trusted-users)"
  # The failing command: its exit status is the lab's.
  nix copy --from "${CACHE_URL}" --to "${LAB_TMP}/store" \
    --option require-sigs true --option trusted-public-keys \
    'cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=' \
    "${FIRN_HELLO}"
}

main "$@"
