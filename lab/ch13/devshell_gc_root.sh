#!/usr/bin/env bash
#
# nix-direnv keeps the dev shell alive: `use flake` builds the shell with an
# out-link under .direnv/, and an out-link made by nix is a GC root. The lab
# loads the project of fixtures/direnv_project.sh through direnv, lists
# .direnv/, finds the links in `nix-store --gc --print-roots`, then deletes
# .direnv/ and looks again: with the link gone, the root is gone and the
# shell's closure can be collected. Nothing is collected here. Roots are
# taken from the print-roots listing; the hashes in names are volatile.

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=lab/ch13/fixtures/direnv_project.sh
source "${FIRN_ROOT}/lab/ch13/fixtures/direnv_project.sh"

#######################################
# Print the GC roots that live in the project's .direnv directory.
# Globals:
#   LAB_TMP
# Outputs:
#   One line per root, with LAB_TMP and store hashes abbreviated.
#######################################
project_roots() {
  nix-store --gc --print-roots 2>/dev/null \
    | grep -F "${LAB_TMP}/proj/.direnv/" \
    | sed -E \
      -e "s|${LAB_TMP}|\$LAB_TMP|" \
      -e 's|/nix/store/[a-z0-9]{32}-|/nix/store/<hash>-|' \
      -e 's|/flake-inputs/[a-z0-9]{32}-|/flake-inputs/<hash>-|' \
      -e 's|-[a-z0-9]{32,}|-<hash>|' \
    | LC_ALL=C sort || true
}

main() {
  direnv_project::setup with
  direnv exec . true >/dev/null 2>&1

  echo "== .direnv/"
  find .direnv -mindepth 1 -maxdepth 1 -printf '%f\n' | LC_ALL=C sort \
    | sed -E 's|-[a-z0-9]{32,}|-<hash>|'

  echo
  echo "== gc roots under .direnv/"
  project_roots

  echo
  echo "== after rm -rf .direnv"
  rm -rf .direnv
  printf 'roots under .direnv/: %d\n' "$(project_roots | wc -l)"
}

main "$@"
