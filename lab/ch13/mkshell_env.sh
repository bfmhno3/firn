#!/usr/bin/env bash
#
# What the c dev shell looks like from the inside. Section 1 reads the shell
# through `nix print-dev-env --json`: how many variables it declares, which
# variables hold the inputs and the compiler flags, and whether firn-hello's
# own env.NIX_CFLAGS_COMPILE (-DFIRN_GREETING) came along through inputsFrom.
# Section 2 counts what a child process sees under `env -i` for the three
# shells. Section 3 shows that a derivation which refuses to build still gives
# a working `nix develop`: the shell never runs the build phases. Counts are
# volatile (they move with nixpkgs) and printed with a `volatile:` prefix.

set -o errexit
set -o nounset
set -o pipefail

readonly SHELLS="${FIRN_ROOT}#devShells.x86_64-linux"
readonly REFUSES="${FIRN_ROOT}/lab/ch13/fixtures/refuses.nix"

#######################################
# Remove the hash from store paths so they read as name-version.
#######################################
strip_hash() {
  sed -E 's|/nix/store/[a-z0-9]{32}-||g'
}

#######################################
# Print the words of one variable of a print-dev-env JSON document.
# Arguments:
#   The JSON document, the variable name.
#######################################
var_words() {
  jq -r ".variables.$2.value" <<<"$1" | tr ' ' '\n' | grep -v '^$'
}

#######################################
# Section 1: variables, inputs and flags of the c shell.
#######################################
show_variables() {
  local json
  json="$(nix print-dev-env --json "${SHELLS}.c" 2>/dev/null)"

  echo "== variables of the c shell (print-dev-env --json)"
  jq -r '"volatile: variables \(.variables | length)",
    "volatile: functions \(.bashFunctions | length)"' <<<"${json}"
  jq -r '.variables | map(.type) | group_by(.)
    | map("volatile: \(.[0]) \(length)") | .[]' <<<"${json}"

  echo
  echo "== buildInputs and NIX_CFLAGS_COMPILE in the c shell"
  echo "buildInputs:"
  var_words "${json}" buildInputs | strip_hash
  echo "NIX_CFLAGS_COMPILE (flags, hashes stripped):"
  var_words "${json}" NIX_CFLAGS_COMPILE \
    | grep -v -e '^-isystem$' -e '^-frandom-seed' \
    | strip_hash | sort | uniq -c
  printf 'FIRN_GREETING flags: %d\n' \
    "$(var_words "${json}" NIX_CFLAGS_COMPILE | grep -c FIRN_GREETING || true)"
  echo "nativeBuildInputs (first 8, hashes stripped):"
  var_words "${json}" nativeBuildInputs | strip_hash | head -n 8
}

#######################################
# Section 2: env var counts seen by a child process.
#######################################
show_counts() {
  local name
  echo
  echo "== env vars seen by a child process under env -i"
  for name in default c python; do
    printf 'volatile: %-8s %s\n' "${name}" \
      "$(env -i HOME="${HOME}" PATH="${PATH}" \
        nix develop "${SHELLS}.${name}" \
        --command bash -c 'env | wc -l' 2>/dev/null | tail -n 1)"
  done
}

#######################################
# Section 3: a derivation that refuses to build.
#######################################
show_refusal() {
  local status=0
  echo
  echo "== a derivation that refuses to build"
  nix build --no-link --file "${REFUSES}" 2>&1 \
    | grep 'not meant' | strip_hash || true
  nix build --no-link --file "${REFUSES}" >/dev/null 2>&1 || status=$?
  echo "nix build exit: ${status}"
  # shellcheck disable=SC2016  # the probe is code for the child shell
  nix develop --file "${REFUSES}" \
    --command bash -c 'echo "nix develop works, IN_NIX_SHELL=${IN_NIX_SHELL}"' \
    2>/dev/null | strip_hash
}

main() {
  show_variables
  show_counts
  show_refusal
}

main "$@"
