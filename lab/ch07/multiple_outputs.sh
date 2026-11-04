#!/usr/bin/env bash
#
# Multiple outputs of the pinned zlib: the outputs list and the closure sizes
# of zlib.out (runtime library) and zlib.dev (headers, pkg-config file).

set -o errexit
set -o nounset
set -o pipefail

readonly pkgs_nix="${FIRN_ROOT}/nix/pkgs.nix"

echo "outputs: $(nix eval --impure --json --expr \
  "(import ${pkgs_nix} { }).zlib.outputs")"
echo "outputName: $(nix eval --impure --raw --expr \
  "(import ${pkgs_nix} { }).zlib.outputName")"

for o in out dev; do
  path="$(nix build --impure --no-link --print-out-paths --expr \
    "(import ${pkgs_nix} { }).zlib.${o}")"
  echo "== zlib.${o}: ${path}"
  echo "self size: $(nix path-info -s "${path}" | cut -f2 | tr -d ' ') bytes"
  echo "closure size: $(nix path-info -S "${path}" | cut -f2 | tr -d ' ') bytes"
done
echo "== zlib.dev references"
nix-store -q --references "$(nix build --impure --no-link --print-out-paths \
  --expr "(import ${pkgs_nix} { }).zlib.dev")"
