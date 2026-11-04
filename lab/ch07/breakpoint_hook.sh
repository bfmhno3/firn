#!/usr/bin/env bash
#
# breakpointHook: a build that fails keeps the builder alive (`sleep`) and
# prints how to attach. Here the build is cut off by `nix build --timeout 20`,
# so the lab ends in bounded time and Nix kills the builder. Prints the
# breakpointHook lines of the build log (the random attach id is masked), the
# error and the exit status of nix build (non-zero is the expected result).

set -o errexit
set -o nounset
set -o pipefail

cd "${LAB_TMP}"
cat >breakpoint_demo.nix <<EOF
let
  pkgs = import ${FIRN_ROOT}/nix/pkgs.nix { };
in
pkgs.runCommand "breakpoint-demo" { nativeBuildInputs = [ pkgs.breakpointHook ]; } ''
  echo before
  exit 1
''
EOF

status=0
nix build --no-link --timeout 20 -L -f breakpoint_demo.nix >log.txt 2>&1 || status=$?
grep -E 'breakpoint-demo> |^error:' log.txt \
  | sed -E 's|/nix/store/[0-9a-z]{32}-attach|<attach>|; s|attach [0-9]+$|attach <id>|'
echo "nix build exit status: ${status}"
