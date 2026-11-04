#!/usr/bin/env bash
#
# Fixed-output derivations: the out path is derived from outputHash, not from
# the builder. Two different scripts that both produce the bytes "firn" and
# declare the same outputHash get different .drv files but one shared out path.

set -o errexit
set -o nounset
set -o pipefail

readonly prelude="${FIRN_ROOT}/lab/ch06/fixtures/prelude.nix"
hash="$(printf '%s' firn | sha256sum | cut -d' ' -f1)"
hash="$(nix hash convert --hash-algo sha256 --to sri "${hash}")"
readonly hash

#######################################
# Fixed-output derivation expression whose script is given.
# Arguments:
#   Shell script text for the builder.
# Outputs:
#   Writes a Nix expression to stdout.
#######################################
fod_expr() {
  cat <<NIX
let p = import ${prelude};
in derivation {
  name = "firn-fod";
  inherit (p) system;
  builder = "\${p.busybox}/bin/sh";
  args = [ "-c" ''$1'' ];
  PATH = "\${p.busybox}/bin";
  outputHashMode = "flat";
  outputHashAlgo = "sha256";
  outputHash = "${hash}";
}
NIX
}

readonly script_a="printf '%s' firn > \$out"
readonly script_b="echo firn | tr -d '\\n' > \$out"

echo "outputHash: ${hash}"
for script in "${script_a}" "${script_b}"; do
  expr="$(fod_expr "${script}")"
  echo "script: ${script}"
  echo "  drvPath: $(nix eval --impure --raw --expr "(${expr}).drvPath")"
  echo "  outPath: $(nix eval --impure --raw --expr "(${expr}).outPath")"
  echo "  built:   $(nix build --impure --no-link --print-out-paths --expr "${expr}")"
done
