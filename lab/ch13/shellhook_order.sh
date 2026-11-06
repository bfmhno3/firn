#!/usr/bin/env bash
#
# Order in which shellHooks run when a shell uses inputsFrom. mkShell
# concatenates the hooks of the inputsFrom list in reverse order and puts the
# shell's own hook last (lib.reverseList inputsFrom ++ [ attrs ] in nixpkgs'
# mkShell). fixtures/hooks.nix has shells a and b and `combined` with
# inputsFrom = [ a b ]. Also shown: the hook runs before the --command, and
# print-dev-env ends with the line that evaluates it.

set -o errexit
set -o nounset
set -o pipefail

readonly FIXTURE="${FIRN_ROOT}/lab/ch13/fixtures/hooks.nix"

main() {
  echo "== nix develop combined --command echo command"
  nix develop --file "${FIXTURE}" combined \
    --command echo "command: runs after the hooks" 2>/dev/null

  echo
  echo "== the merged shellHook attribute"
  nix eval --raw --file "${FIXTURE}" combined.shellHook
  echo

  echo
  echo "== end of print-dev-env"
  nix print-dev-env --file "${FIXTURE}" combined 2>/dev/null \
    | grep -v '^$' | tail -n 1
}

main "$@"
