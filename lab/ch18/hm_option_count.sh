#!/usr/bin/env bash
#
# How many `programs.*` options does the demo evaluation know? The count comes
# from optionAttrSetToDocList over options.programs (what the manual's option
# list is built from: hidden and internal options are left out), so it measures
# what a user can set, not what Home Manager happens to define. Also prints the
# number of distinct `programs.<name>` modules and the five largest.

set -o errexit
set -o nounset
set -o pipefail

main() {
  nix eval --impure --json --file "${FIRN_ROOT}/lab/ch18/fixtures/option_count.nix" \
    | jq .
}

main "$@"
