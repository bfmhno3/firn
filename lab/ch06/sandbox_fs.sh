#!/usr/bin/env bash
#
# What a build sees from the inside: the root directory, the user, HOME, the
# working directory and the environment. The script writes everything to $out;
# the lab builds it and prints the file.

set -o errexit
set -o nounset
set -o pipefail

readonly prelude="${FIRN_ROOT}/lab/ch06/fixtures/prelude.nix"

# shellcheck disable=SC2016 # the script is for the builder, not for this shell
readonly script='
{
  echo "== ls /"; ls /
  echo "== ls /nix/store"; ls /nix/store
  echo "== id"; id
  echo "== HOME"; echo "$HOME"
  echo "== pwd"; pwd
  echo "== env | sort"; env | sort
  echo "== env count"; env | wc -l
} > $out'

out="$(nix build --impure --no-link --print-out-paths --expr "
  let p = import ${prelude};
  in p.raw { name = \"sandbox-fs\"; script = ''${script}''; }")"
echo "out: ${out}"
cat "${out}"
