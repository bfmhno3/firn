#!/usr/bin/env bash
#
# The same copy as local_cache.sh, but the lab key is not in
# trusted-public-keys. The cache is signed, the signature is valid, and Nix
# still refuses: a signature only counts when its key is trusted. The copy
# fails with "lacks a signature by a trusted key".

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=/dev/null
source "${FIRN_ROOT}/lab/ch20/fixtures/make_cache.sh"

main() {
  make_cache
  # The failing command: its exit status is the lab's.
  nix copy --from "${CACHE_URL}" --to "${LAB_TMP}/store" "${FIRN_HELLO}"
}

main "$@"
