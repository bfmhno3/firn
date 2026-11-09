#!/usr/bin/env bash
#
# Shared by local_cache.sh, unsigned_copy_fail.sh and ex_bad_signature.sh:
# builds firn-hello, copies it (with its closure) into a file:// binary cache in
# LAB_TMP/cache and signs every path of the cache with a fresh key. Sourced,
# not run.
#
# Globals set: FIRN_HELLO (store path), PUBLIC_KEY (the signing key's public
# half), CACHE_URL.

#######################################
# Build firn-hello, fill the cache, sign it.
# Globals:
#   FIRN_ROOT, LAB_TMP
#   FIRN_HELLO, PUBLIC_KEY, CACHE_URL (set)
# Arguments:
#   Optional: query string for the cache URL, e.g. "compression=none".
# Environment:
#   FIRN_LAB_SUBJECT: store path to put in the cache instead of firn-hello.
#######################################
make_cache() {
  local query="${1:-}"
  FIRN_HELLO="${FIRN_LAB_SUBJECT:-$(nix build --no-link --print-out-paths \
    "${FIRN_ROOT}#firn-hello")}"
  CACHE_URL="file://${LAB_TMP}/cache${query:+?${query}}"

  nix key generate-secret --key-name firn-lab-1 >"${LAB_TMP}/secret.key"
  # shellcheck disable=SC2034 # read by the scripts that source this file
  PUBLIC_KEY="$(nix key convert-secret-to-public <"${LAB_TMP}/secret.key")"

  nix copy --to "${CACHE_URL}" "${FIRN_HELLO}"
  nix store sign --store "${CACHE_URL}" --key-file "${LAB_TMP}/secret.key" \
    --recursive "${FIRN_HELLO}"
}
