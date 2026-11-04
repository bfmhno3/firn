#!/usr/bin/env bash
#
# A normal (input-addressed) derivation runs busybox wget and cannot reach
# the network: the build sandbox has no network namespace access. Exit status:
# non-zero. (A fixed-output derivation would get network access.)

set -o errexit
set -o nounset
set -o pipefail

readonly prelude="${FIRN_ROOT}/lab/ch06/fixtures/prelude.nix"

# BAD: a plain derivation must not depend on the network.
nix build --impure --no-link -L --expr "
  let p = import ${prelude};
  in p.raw {
    name = \"wget-in-sandbox\";
    script = \"wget -T 5 -O \\\$out http://example.com/\";
  }"
