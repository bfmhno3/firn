#!/usr/bin/env bash
#
# Host only. `nom` (nix-output-monitor) wraps `nix build` and draws a build
# graph. Here it rebuilds mini.site with --rebuild (build again, compare with
# the existing output: mini.site is deterministic, so this passes). Without a
# terminal nom prints its final tree; this keeps the last lines, with colors
# and carriage returns removed. The finish time and duration are volatile.

set -o errexit
set -o nounset
set -o pipefail

system="$(nix eval --raw --impure --expr builtins.currentSystem)"
readonly system

nom build --no-link --rebuild \
  "${FIRN_ROOT}#legacyPackages.${system}.mini.site" 2>&1 \
  | sed -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' \
  | tr '\r' '\n' \
  | grep -E '^(┏|┃|┣|┗)' \
  | sed 's/Finished at .*/volatile: Finished at <time> after <seconds>/' \
  | tail -n 4
