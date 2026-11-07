#!/usr/bin/env bash
#
# builtins.readFile ./secret.txt used inside a config text copies the secret
# into the store when the config is built. Builds fixtures/readfile_config.nix
# and prints the world-readable store file.

set -o errexit
set -o nounset
set -o pipefail

main() {
  local out
  out="$(nix build --no-link --print-out-paths \
    --file "${FIRN_ROOT}/lab/ch17/fixtures/readfile_config.nix")"
  echo "store path: /nix/store/<hash>-${out#/nix/store/*-}"
  echo "mode: $(stat -c %a "${out}")"
  echo "== content"
  cat "${out}"
  grep -q 'firn-lab-readfile-secret-4f2a' "${out}"
}

main "$@"
