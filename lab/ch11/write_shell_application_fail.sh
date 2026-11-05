#!/usr/bin/env bash
#
# writeShellApplication runs ShellCheck at build time. An unquoted variable
# (SC2086) makes the build fail; plain writeShellScriptBin would not notice.

set -o nounset
set -o pipefail

cat >"${LAB_TMP}/bad.nix" <<NIX
let
  pkgs = import ${FIRN_ROOT}/nix/pkgs.nix { };
in
pkgs.writeShellApplication {
  name = "bad-quote";
  # BAD: \$1 is not quoted, ShellCheck SC2086
  text = "echo \$1";
}
NIX

log="${LAB_TMP}/build.log"
nix build --no-link --impure --file "${LAB_TMP}/bad.nix" 2>"${log}"
status=$?
grep -E 'SC[0-9]+|error: Cannot build' "${log}" | sed -E 's|/nix/store/[a-z0-9]{32}-||g'
exit "${status}"
