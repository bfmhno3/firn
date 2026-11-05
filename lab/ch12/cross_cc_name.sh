#!/usr/bin/env bash
#
# The build environment of the aarch64 cross build (`nix develop` on
# pkgsCross.aarch64-multiplatform.firn-hello). $CC and friends carry the
# target triple as a prefix. The cross environment itself puts no unprefixed
# gcc/cc on PATH (under `env -i` `type -p gcc cc` finds nothing); the two
# x86_64 lines below come from the dev shell's gcc leaking through
# `nix develop`, which keeps the caller's PATH.

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
