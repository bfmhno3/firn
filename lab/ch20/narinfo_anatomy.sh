#!/usr/bin/env bash
#
# Fetches the .narinfo of the pinned nixpkgs' `hello` from cache.nixos.org and
# prints it field by field: StorePath, URL, Compression, FileSize, NarHash,
# NarSize, References, Sig. A .narinfo is the cache's answer to "do you have
# this store path?": the file name is the 32-character hash part of the path.

set -o errexit
set -o nounset
set -o pipefail

main() {
  local out hash
  out="$(nix eval --raw --file "${FIRN_ROOT}/nix/pkgs.nix" hello.outPath)"
  hash="$(basename "${out}" | cut -c1-32)"
  echo "GET https://cache.nixos.org/${hash}.narinfo"
  curl --silent --show-error --fail "https://cache.nixos.org/${hash}.narinfo" \
    | sed -e 's|^Sig: .*|Sig: <base64 ed25519 signature by cache.nixos.org-1>|'
}

main "$@"
