#!/usr/bin/env bash
#
# Reference scanning: after a build Nix greps every output for the 32-char
# hash part of each store path in the build's input closure. A match becomes a
# reference. Three outputs: one mentions busybox's full path, one only the
# hash part of it, one nothing.

set -o errexit
set -o nounset
set -o pipefail

readonly prelude="${FIRN_ROOT}/lab/ch06/fixtures/prelude.nix"

#######################################
# Build a raw derivation and list its references.
# Arguments:
#   Name, Nix string expression for the text the script echoes.
# Outputs:
#   Writes the name, the output content and the references to stdout.
#######################################
scan() {
  local name="$1" text="$2" out
  out="$(nix build --impure --no-link --print-out-paths --expr "
    let p = import ${prelude};
    in p.raw {
      name = \"${name}\";
      script = \"echo '\" + ${text} + \"' > \\\$out\";
    }")"
  echo "== ${name}"
  echo "content: $(cat "${out}")"
  echo "references:"
  nix-store -q --references "${out}" | sed 's/^/  /'
  echo "  ($(nix-store -q --references "${out}" | wc -l) total)"
}

# shellcheck disable=SC2016 # ${...} is Nix interpolation, not shell
scan mentions-path '"uses ${p.busybox}/bin/sh"'
# shellcheck disable=SC2016 # same
scan mentions-hash-only \
  '"hash ${builtins.substring 11 32 (builtins.unsafeDiscardStringContext (toString p.busybox))}"'
scan mentions-nothing '"no store paths here"'
