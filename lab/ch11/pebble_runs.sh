#!/usr/bin/env bash
#
# The packaged pebble runs an example from its own fetched source tree:
# `pebble run examples/fib.pebble` prints fib(20) = 6765.

set -o errexit
set -o nounset
set -o pipefail

out="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#pebble")"
src="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#pebble.src")"

result="$("${out}/bin/pebble" run "${src}/examples/fib.pebble")"
echo "pebble run examples/fib.pebble -> ${result}"
[[ "${result}" == 6765 ]] || exit 1
