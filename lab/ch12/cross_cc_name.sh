#!/usr/bin/env bash
#
# The build environment of the aarch64 cross build (`nix develop` on
# pkgsCross.aarch64-multiplatform.firn-hello). $CC and friends carry the
# target triple as a prefix; the unprefixed gcc/cc on PATH are still the
# build platform's compilers. `-dumpmachine` says which is which.

set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC2016  # the script runs inside the build environment
nix develop --file "${FIRN_ROOT}/nix/pkgs.nix" pkgsCross.aarch64-multiplatform.firn-hello \
  --command bash -c '
    for v in CC CXX LD AR STRIP PKG_CONFIG; do
      echo "${v}=${!v}"
    done
    echo "$CC -dumpmachine: $("${CC}" -dumpmachine)"
    echo "gcc -dumpmachine: $(gcc -dumpmachine)"
    echo "cc -dumpmachine: $(cc -dumpmachine)"
    echo "NIX_CC=${NIX_CC}"
  ' 2>/dev/null | sed -E 's|/nix/store/[a-z0-9]{32}-||g'
