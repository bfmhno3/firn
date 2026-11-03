#!/usr/bin/env bash
#
# cleanSource keeps the store path of a source tree stable against workspace
# noise: touching out/x does not change it, editing a tracked file does. A
# plain builtins.path (no filter) changes in both cases. Everything happens in
# a copy under LAB_TMP.

set -o errexit
set -o nounset
set -o pipefail

readonly proj="${LAB_TMP}/proj"
mkdir -p "${proj}/out" "${proj}/.git" "${proj}/src"
echo 'int main(void) { return 0; }' >"${proj}/src/main.c"
echo 'tracked' >"${proj}/README"
echo 'x' >"${proj}/.git/HEAD"

#######################################
# Store path of the project through a builtins.path variant.
# Arguments:
#   "clean" for Firn's cleanSource, "raw" for an unfiltered builtins.path.
# Outputs:
#   Writes the store path to stdout.
#######################################
store_path() {
  local expr
  if [[ "$1" == clean ]]; then
    expr="(import ${FIRN_ROOT}/lib).cleanSource (/. + \"${proj}\")"
  else
    expr="builtins.path { path = /. + \"${proj}\"; name = \"source\"; }"
  fi
  nix eval --impure --raw --expr "${expr}"
}

echo "clean, initial:            $(store_path clean)"
echo "raw, initial:              $(store_path raw)"
echo 'junk' >"${proj}/out/x"
echo 'gitjunk' >"${proj}/.git/index"
echo "clean, after touching out: $(store_path clean)"
echo "raw, after touching out:   $(store_path raw)"
echo 'changed' >"${proj}/README"
echo "clean, after edit:         $(store_path clean)"
echo "== files inside the clean copy"
ls -A "$(store_path clean)"
