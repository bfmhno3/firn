#!/usr/bin/env bash
#
# Shows that "${./file}" is content addressed: one changed byte gives a new
# store path, while the same content under a different name only changes the
# name part.

set -o errexit
set -o nounset
set -o pipefail

# 这里要的就是字面的 ${...}，交给 Nix 去插值。
# shellcheck disable=SC2016
readonly EXPR='"${./note.txt}"'
# shellcheck disable=SC2016
readonly OTHER='"${./other-name.txt}"'

store_path() {
  nix eval --impure --raw --expr "$1"
}

cd "${LAB_TMP}"
printf 'firn note\n' >note.txt
before="$(store_path "${EXPR}")"
printf 'firn Note\n' >note.txt
after="$(store_path "${EXPR}")"
printf 'firn note\n' >note.txt
cp note.txt other-name.txt
renamed="$(store_path "${OTHER}")"

echo "before  ${before}"
echo "after   ${after}"
echo "renamed ${renamed}"
if [[ "${before%%-*}" != "${after%%-*}" ]]; then
  echo "one byte changed: hash part differs"
fi
echo "same content, other name, hash part: ${before%%-*} vs ${renamed%%-*}"
