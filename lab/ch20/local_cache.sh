#!/usr/bin/env bash
#
# A binary cache is a directory of files. This lab makes one in LAB_TMP:
# generates a signing key, copies firn-hello (with its closure) to a file://
# cache, signs the cache with the key and prints the .narinfo of firn-hello.
# Then it copies from the cache into an empty local store, trusting only the
# lab key (`--option trusted-public-keys`), and checks that the path arrived.
# The signature and key lines are random per run and are marked `volatile:`.

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=/dev/null
source "${FIRN_ROOT}/lab/ch20/fixtures/make_cache.sh"

main() {
  make_cache
  echo "key name: ${PUBLIC_KEY%%:*}"
  echo "volatile: public key ${PUBLIC_KEY}"

  local narinfo
  narinfo="${LAB_TMP}/cache/$(basename "${FIRN_HELLO}" | cut -c1-32).narinfo"
  echo "== ${narinfo##*/}"
  sed -e 's|^Sig: |volatile: Sig: |' "${narinfo}"
  echo "== files in the cache"
  echo "narinfo files: $(find "${LAB_TMP}/cache" -name '*.narinfo' | wc -l)"
  echo "nar files: $(find "${LAB_TMP}/cache/nar" -type f | wc -l)"
  ls "${LAB_TMP}/cache"

  nix copy --from "${CACHE_URL}" --to "${LAB_TMP}/store" \
    --option require-sigs true \
    --option trusted-public-keys "${PUBLIC_KEY}" "${FIRN_HELLO}"
  nix path-info --store "${LAB_TMP}/store" "${FIRN_HELLO}"
  echo "copy with the lab key trusted: ok"
}

main "$@"
