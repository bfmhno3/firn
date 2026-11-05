#!/usr/bin/env bash
#
# Closure size and path count of the four real packages, from the same build
# the flake exposes. `nix path-info -S` prints the closure size, `-r` lists the
# closure. Python's closure is the largest of the Python/Rust/Bash/C set:
# the interpreter and its standard-library dependencies are runtime inputs.

set -o errexit
set -o nounset
set -o pipefail

printf '%-12s %12s %6s\n' package closure paths
for name in firn-hello cairn sift pebble; do
  out="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#${name}")"
  size="$(nix path-info -Sh "${out}" | awk '{ print $2 $3 }')"
  count="$(nix path-info -r "${out}" | wc -l)"
  printf '%-12s %12s %6d\n' "${name}" "${size}" "${count}"
done
