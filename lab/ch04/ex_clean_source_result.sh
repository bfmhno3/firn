#!/usr/bin/env bash
#
# Exercise answer: a cleanSource variant (clean_source_v2.nix) that keeps a
# regular file named `result` in a subdirectory but still drops result
# symlinks (including result-*), .git, .direnv and out. Exits 1 on mismatch.

set -o errexit
set -o nounset
set -o pipefail

readonly proj="${LAB_TMP}/ex_result"
mkdir -p "${proj}/src/out" "${proj}/.git"
echo n >"${proj}/src/main.c"
echo r >"${proj}/src/result"
echo x >"${proj}/src/out/obj"
echo y >"${proj}/.git/HEAD"
ln -s /nix/store/nowhere "${proj}/result"
ln -s /nix/store/nowhere "${proj}/result-1"

clean="$(nix eval --impure --raw --expr \
  "(import ${FIRN_ROOT}/lab/ch04/clean_source_v2.nix) (/. + \"${proj}\")")"
actual="$(cd "${clean}" && find . | sort)"
expected="$(printf '%s\n' . ./src ./src/main.c ./src/result)"
echo "${actual}"
if [[ "${actual}" != "${expected}" ]]; then
  echo "mismatch, expected:" >&2
  echo "${expected}" >&2
  exit 1
fi
echo "ok: src/result kept; result, result-1, .git, src/out dropped"
