#!/usr/bin/env bash
#
# `file` on the four firn-hello binaries: native (glibc, dynamic), pkgsStatic
# (musl, static), pkgsMusl (musl, dynamic) and pkgsCross aarch64 (glibc,
# dynamic, ARM64). The store paths in the interpreter field are replaced by
# their package names so the output is comparable.

set -o errexit
set -o nounset
set -o pipefail

for name in firn-hello firn-hello-static firn-hello-musl firn-hello-aarch64; do
  out="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#${name}")"
  printf '== %s\n' "${name}"
  file --brief "${out}/bin/firn-hello" \
    | sed -E 's|/nix/store/[a-z0-9]{32}-||g; s/, BuildID\[sha1\]=[0-9a-f]+//'
done
