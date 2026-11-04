#!/usr/bin/env bash
#
# A fixed-output derivation whose declared hash is wrong. The build fails and
# Nix prints the hash it declared (`specified:`) next to the one it computed
# (`got:`). Exit status: non-zero.

set -o errexit
set -o nounset
set -o pipefail

readonly prelude="${FIRN_ROOT}/lab/ch06/fixtures/prelude.nix"
wrong="$(printf '%s' not-firn | sha256sum | cut -d' ' -f1)"
wrong="$(nix hash convert --hash-algo sha256 --to sri "${wrong}")"
readonly wrong

# BAD: outputHash is the hash of "not-firn", the script writes "firn".
nix build --impure --no-link --expr "
  let p = import ${prelude};
  in derivation {
    name = \"firn-fod-wrong\";
    inherit (p) system;
    builder = \"\${p.busybox}/bin/sh\";
    args = [ \"-c\" \"printf '%s' firn > \\\$out\" ];
    outputHashMode = \"flat\";
    outputHashAlgo = \"sha256\";
    outputHash = \"${wrong}\";
  }"
