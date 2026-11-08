#!/usr/bin/env bash
#
# Shows what `nix build --rebuild` does with a package that is not
# reproducible. mini.nondeterministic writes the kernel's random UUID into its
# output, so the second build differs from the first and Nix fails with
# "may not be deterministic". The build runs in a throwaway local store inside
# LAB_TMP, so the host store keeps no trace of this package.

set -o errexit
set -o nounset
set -o pipefail

main() {
  local attr="${FIRN_ROOT}#legacyPackages.x86_64-linux.mini.nondeterministic"
  local store="${LAB_TMP}/store"
  nix build --store "${store}" --no-link --print-out-paths "${attr}"
  # This is the command that fails: its exit status is the lab's.
  nix build --store "${store}" --no-link --rebuild "${attr}"
}

main "$@"
