#!/usr/bin/env bash
#
# The packaged sift runs with `--help` (first lines), and its closure holds
# a CPython 3.14: a Python application drags the interpreter and every
# dependency's wheel contents into the runtime closure.

set -o errexit
set -o nounset
set -o pipefail

out="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#sift")"

echo "== sift --help (first lines)"
"${out}/bin/sift" --help | head -n 8

echo
echo "== python in the closure"
nix path-info -r "${out}" | sed 's|^/nix/store/[a-z0-9]*-||' | grep -E '^python3-3\.14' || {
  echo "no python3 3.14 in closure" >&2
  exit 1
}
