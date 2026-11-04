#!/usr/bin/env bash
#
# What is inside a .drv: `nix derivation show` renders it as JSON, `cat` shows
# the raw ATerm file Nix actually stores. Also prints the size of the file.

set -o errexit
set -o nounset
set -o pipefail

readonly file="${FIRN_ROOT}/lab/ch06/raw_hello.nix"

drv="$(nix eval --raw --file "${file}" drvPath)"
echo "drv: ${drv}"
echo "size: $(stat -c %s "${drv}") bytes"
echo
echo "== nix derivation show (top-level fields)"
nix derivation show --file "${file}" | jq 'keys'
echo
echo "== nix derivation show (derivation fields)"
nix derivation show --file "${file}" \
  | jq '.derivations | to_entries[0].value | {name, system, builder, args, outputs, env: (.env | keys), inputs}'
echo
echo "== cat of the .drv (ATerm)"
cat "${drv}"
echo
