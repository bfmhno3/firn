#!/usr/bin/env bash
#
# Exercise: tamper with one byte of a NAR in the local cache. The cache is
# built uncompressed (`compression=none`) so the file under nar/ is the NAR
# itself. The signature in the .narinfo still verifies (it covers the NarHash,
# not the file), but the NAR's hash no longer matches and the copy fails.
# The lab exits 0 when the copy fails and 1 when the tampered copy succeeds.

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=/dev/null
source "${FIRN_ROOT}/lab/ch20/fixtures/make_cache.sh"

main() {
  make_cache "compression=none"

  local narinfo nar
  narinfo="${LAB_TMP}/cache/$(basename "${FIRN_HELLO}" | cut -c1-32).narinfo"
  nar="${LAB_TMP}/cache/$(sed -n 's|^URL: ||p' "${narinfo}")"
  echo "NAR: ${nar#"${LAB_TMP}/cache/"} ($(stat --format %s "${nar}") bytes)"

  # Flip the first byte of the string "crc32" in firn-hello's binary: a byte
  # of file contents, not of the NAR framing (the framing has its own errors).
  local offset
  offset="$(grep --text --byte-offset --only-matching crc32 "${nar}" \
    | head -n 1 | cut -d: -f1)"
  echo "flipping byte at offset ${offset}"
  chmod u+w "${nar}"
  printf '\xff' | dd of="${nar}" bs=1 seek="${offset}" conv=notrunc status=none

  if nix copy --from "${CACHE_URL}" --to "${LAB_TMP}/store" \
    --option require-sigs true \
    --option trusted-public-keys "${PUBLIC_KEY}" "${FIRN_HELLO}"; then
    echo "tampered NAR was accepted" >&2
    return 1
  fi
  echo "tampered NAR rejected"
}

main "$@"
