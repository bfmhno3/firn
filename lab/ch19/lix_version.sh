#!/usr/bin/env bash
#
# Builds (substitutes) the `lix` package of the pinned nixpkgs and runs its
# `nix --version`. Lix ships the same command name as upstream Nix, so the
# version string is how you tell them apart. Nothing is installed: the binary
# is run from its store path. Only the first line of the output is printed; the
# others list the paths of the user's configuration files.

set -o errexit
set -o nounset
set -o pipefail

main() {
  local out
  out="$(nix build --no-link --print-out-paths --impure --expr \
    "(import ${FIRN_ROOT}/nix/pkgs.nix { }).lix.out")"
  # 只留第一行：后面几行列出用户配置文件的路径。
  "${out}/bin/nix" --version | sed -n 1p
}

main "$@"
