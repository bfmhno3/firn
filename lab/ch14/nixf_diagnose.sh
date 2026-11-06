#!/usr/bin/env bash
#
# Runs nixf-diagnose (the nixf parser and linter behind nixd) on the
# contrib file. It needs no nixpkgs checkout, so this lab is not host only.
# Prints the diagnostics and the exit status.

set -o errexit
set -o nounset
set -o pipefail

# nixf-diagnose colors its output even when stdout is not a terminal.
strip_ansi() {
  sed -E 's/\x1b\[[0-9;]*m//g'
}

file="${FIRN_ROOT}/contrib/nixpkgs/pkgs/by-name/ca/cairn/package.nix"

echo "== nixf-diagnose contrib/nixpkgs/pkgs/by-name/ca/cairn/package.nix"
(cd "${FIRN_ROOT}" && nixf-diagnose "${file#"${FIRN_ROOT}/"}") 2>&1 | strip_ansi
status="${PIPESTATUS[0]}"
echo "exit status: ${status}"

echo
echo "== the same on a file with an unused binding and a missing semicolon"
printf '{ x }:\nlet unused = 1; in {\n  a = x\n}\n' >"${LAB_TMP}/bad.nix" # BAD
(cd "${LAB_TMP}" && nixf-diagnose bad.nix) 2>&1 | strip_ansi || true
