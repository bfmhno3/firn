#!/usr/bin/env bash
#
# What pure evaluation refuses: one expression per line, the last line of
# the error (or the value) after it.

set -o nounset

exprs=(
  'builtins.currentSystem'
  'builtins.currentTime'
  'builtins.getEnv "HOME"'
  'builtins.readFile /etc/hostname'
  'builtins.readDir /etc'
  'builtins.pathExists /etc/hostname'
  '<nixpkgs>'
  'builtins.fetchurl "https://example.org/x"'
  'builtins.fetchGit "https://github.com/bfmhno3/cairn"'
  'builtins.storePath /nix/store/lcxc2z1h2g8wq8dxfpizy1di85kyxnqx-hello-2.12.3'
)
for expr in "${exprs[@]}"; do
  echo "\$ nix eval --pure-eval --expr '${expr}'"
  nix eval --pure-eval --expr "${expr}" 2>&1 | grep -E '^(error|[^ ]|\s+error)' | tail -1
done
