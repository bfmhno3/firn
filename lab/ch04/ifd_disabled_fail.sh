#!/usr/bin/env bash
#
# The same import-from-derivation as ifd.sh, but with
# allow-import-from-derivation turned off (as Hydra does): evaluation stops
# instead of building. The name carries a timestamp so the derivation is
# never already built.

set -o errexit
set -o nounset
set -o pipefail

nix eval --impure --option allow-import-from-derivation false --expr "
  let pkgs = import ${FIRN_ROOT}/nix/pkgs.nix { };
  in import (pkgs.runCommand \"gen-${EPOCHREALTIME/./}\" { } ''
    echo '{ x = 42; }' > \$out
  '')
"
