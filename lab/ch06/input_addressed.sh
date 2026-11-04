#!/usr/bin/env bash
#
# Input-addressed: the out path is a hash of the .drv, not of the output.
# Two derivations differ only in an env attribute the builder never reads.
# They produce byte-identical outputs at different store paths.

set -o errexit
set -o nounset
set -o pipefail

readonly prelude="${FIRN_ROOT}/lab/ch06/fixtures/prelude.nix"

#######################################
# Build the lab derivation with a given value of the unused attribute.
# Arguments:
#   Value of the unused attribute, "drvPath" or "outPath" or "build".
# Outputs:
#   Writes the requested path to stdout.
#######################################
show() {
  local unused="$1" what="$2"
  local expr="
    let p = import ${prelude};
    in derivation {
      name = \"same-bytes\";
      inherit (p) system;
      builder = \"\${p.busybox}/bin/sh\";
      args = [ \"-c\" \"echo 'same bytes' > \$out\" ];
      PATH = \"\${p.busybox}/bin\";
      unused = \"${unused}\";
    }"
  if [[ "${what}" == build ]]; then
    nix build --impure --no-link --print-out-paths --expr "${expr}"
  else
    nix eval --impure --raw --expr "(${expr}).${what}"
  fi
}

for unused in one two; do
  echo "unused = ${unused}"
  echo "  drvPath: $(show "${unused}" drvPath)"
  echo "  outPath: $(show "${unused}" outPath)"
done

out_one="$(show one build)"
out_two="$(show two build)"
echo "sha256 of the outputs:"
sha256sum "${out_one}" "${out_two}"
if cmp -s "${out_one}" "${out_two}"; then
  echo "outputs are byte-identical"
fi
