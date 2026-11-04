#!/usr/bin/env bash
#
# Setup hooks at work: a mkShell with pkg-config and zlib. Nothing in the
# shell expression sets PKG_CONFIG_PATH; pkg-config's setup hook (run by
# $stdenv/setup) adds each buildInput's lib/pkgconfig. Prints the variable,
# the hook files of the pinned pkg-config and what pkg-config then finds.

set -o errexit
set -o nounset
set -o pipefail

cd "${LAB_TMP}"
cat >shell.nix <<EOF
let
  pkgs = import ${FIRN_ROOT}/nix/pkgs.nix { };
in
pkgs.mkShell {
  packages = [
    pkgs.pkg-config
    pkgs.zlib
  ];
}
EOF

# shellcheck disable=SC2016 # the script is for the inner shell
nix-shell shell.nix --run '
  echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH}"
  echo "== nix-support of pkg-config-wrapper"
  ls "$(dirname "$(dirname "$(command -v pkg-config)")")/nix-support"
  echo "== pkg-config --cflags --libs zlib"
  pkg-config --cflags --libs zlib
  echo "== pkg-config --modversion zlib"
  pkg-config --modversion zlib
'
