#!/usr/bin/env bash
#
# Instantiate and realise lab/ch06/raw_hello.nix separately: the .drv and the
# planned out path exist after evaluation, the out path itself only after the
# build. Then print the content of the out path.

set -o errexit
set -o nounset
set -o pipefail

readonly file="${FIRN_ROOT}/lab/ch06/raw_hello.nix"

echo "drvPath: $(nix eval --raw --file "${file}" drvPath)"
echo "outPath: $(nix eval --raw --file "${file}" outPath)"
out="$(nix build --no-link --print-out-paths -f "${file}")"
echo "built:   ${out}"
echo "content: $(cat "${out}")"
