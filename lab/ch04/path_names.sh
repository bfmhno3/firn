#!/usr/bin/env bash
#
# Two checkouts of the same project in differently named directories: the
# default store name follows the directory, builtins.path with a fixed name
# does not.

set -o errexit
set -o nounset
set -o pipefail

readonly root="${LAB_TMP:-/tmp}/checkouts"
for d in checkout-a checkout-b; do
  mkdir -p "${root}/${d}/src/out" "${root}/${d}/.git"
  echo hi >"${root}/${d}/f.txt"
  echo n >"${root}/${d}/src/main.c"
  echo x >"${root}/${d}/src/out/obj"
  echo y >"${root}/${d}/.git/HEAD"
  echo r >"${root}/${d}/src/result"
  ln -sf nowhere "${root}/${d}/result-1"
done

for d in checkout-a checkout-b; do
  echo "== ${d}"
  nix eval --impure --raw --expr "\"\${/. + \"${root}/${d}\"}\""
  echo
  nix eval --impure --raw --expr \
    "builtins.path { path = /. + \"${root}/${d}\"; name = \"source\"; }"
  echo
  nix eval --impure --raw --expr \
    "(import ${FIRN_ROOT}/lib).cleanSource (/. + \"${root}/${d}\")"
  echo
done
echo "== files in the cleaned copy"
clean="$(nix eval --impure --raw --expr \
  "(import ${FIRN_ROOT}/lib).cleanSource (/. + \"${root}/checkout-a\")")"
(cd "${clean}" && find . | sort)
