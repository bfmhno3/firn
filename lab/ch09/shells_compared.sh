#!/usr/bin/env bash
#
# Three ways into an environment with `hello`, compared by what the child
# process sees. Each command runs under `env -i` (only HOME and PATH) so the
# counts do not depend on the caller's shell. The env var counts are volatile:
# they move with Nix and nixpkgs versions. What is stable: nix-shell exports
# the derivation's variables (stdenv, out, ...), `nix shell` only edits PATH,
# and `nix develop` builds the same build environment as nix-shell but keeps
# it in shell variables, so an unexported $stdenv is invisible to a child.
# `nix develop` puts the build inputs of hello on PATH, not hello itself.

set -o errexit
set -o nounset
set -o pipefail

nixpkgs="$(nix eval --raw --file "${FIRN_ROOT}/nix/pins.nix" nixpkgs)"
readonly nixpkgs

# shellcheck disable=SC2016  # the probe is code for the child shell
readonly probe='echo "env vars: $(env | wc -l)"
if [[ -n "${stdenv:-}" ]]; then echo "stdenv:   set"; else echo "stdenv:   unset"; fi
if command -v hello >/dev/null; then echo "hello:    on PATH"; else echo "hello:    not on PATH"; fi'

#######################################
# Run the probe in a clean environment.
# Arguments:
#   The command that starts the environment, up to and including the
#   flag that takes a command string.
#######################################
clean() {
  env -i HOME="${HOME}" PATH="${PATH}" "$@" "${probe}"
}

echo "== nix-shell -p hello -I nixpkgs=<pin> --run"
clean nix-shell -p hello -I "nixpkgs=${nixpkgs}" --run

echo
echo "== nix shell -f nix/pkgs.nix hello -c bash -c"
clean nix shell -f "${FIRN_ROOT}/nix/pkgs.nix" hello -c bash -c

echo
echo "== nix develop -f nix/pkgs.nix hello -c bash -c"
clean nix develop -f "${FIRN_ROOT}/nix/pkgs.nix" hello -c bash -c
