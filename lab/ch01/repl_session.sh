#!/usr/bin/env bash
#
# Drives `nix repl` with the pinned nixpkgs from a here-document.

set -o errexit
set -o nounset
set -o pipefail

#######################################
# Strip ANSI escapes and carriage returns from stdin.
#######################################
clean() {
  sed -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' -e 's/\r$//'
}

nix repl --file "${FIRN_ROOT}/nix/pkgs.nix" 2>&1 <<'REPL' | clean
:t 1
:t hello
hello.name
:doc builtins.map
:q
REPL
