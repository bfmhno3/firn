#!/usr/bin/env bash
#
# Host only. `nom` (nix-output-monitor) wraps `nix build` and draws a build
# graph. `mini.site` is usually already in the store, so building it shows
# nothing to do (nom prints only "site" as done, 0 s), and `--rebuild` is a
# check run that does not show a build either. To see a real "Builds" line
# this builds a fresh derivation: a `runCommand` whose name carries the
# current time, so its hash is new on every run and it must be built (it
# sleeps one second). Without a terminal nom prints its final tree; this keeps
# the graph lines, with colors and carriage returns removed. The build time,
# the finish time and the derivation name are volatile.

set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC2016  # the Nix expression is single-quoted on purpose
nom build --no-link --impure --expr '
  let
    pkgs = import ((builtins.getEnv "FIRN_ROOT") + "/nix/pkgs.nix") { };
  in
  pkgs.runCommand "nom-demo-${toString builtins.currentTime}" { } "sleep 1; echo ok > $out"
' 2>&1 \
  | sed -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' \
    -e 's/┏━ Dependency Graph:/\n&/' \
  | tr '\r' '\n' \
  | awk '/Dependency Graph/ { block = "" } { block = block $0 "\n" } END { printf "%s", block }' \
  | grep -E '^(┏|┃|┣|┗)' \
  | sed -e 's/nom-demo-[0-9]*/nom-demo-<time>/' \
    -e 's/⏱ [0-9]*s/⏱ <seconds>s/' \
    -e 's/Finished at .* after [0-9]*s/Finished at <time> after <seconds>s/' \
  | sed 's/^/volatile: /'
