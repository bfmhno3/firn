#!/usr/bin/env bash
#
# How big is "a module system" in practice? Evaluates a minimal NixOS
# configuration (fixtures/minimal_nixos.nix: no services, tmpfs root, no
# bootloader) from the pinned nixpkgs and prints how many options
# `lib.collect lib.isOption` finds, how many modules module-list.nix lists,
# and the median wall time of five evaluations of the system's drvPath.
# The counts are fixed by the pin; the times are volatile.

set -o errexit
set -o nounset
set -o pipefail

readonly MINIMAL="${FIRN_ROOT}/lab/ch15/fixtures/minimal_nixos.nix"
readonly RUNS=5

#######################################
# Evaluate a Nix expression that sees `os`, the minimal NixOS evaluation.
# Globals:
#   MINIMAL
# Arguments:
#   Expression text using `os`.
# Outputs:
#   The value printed by nix eval on stdout.
#######################################
eval_os() {
  nix eval --impure --raw --expr \
    "let os = import ${MINIMAL}; in toString (${1})"
}

#######################################
# Print the median of the numbers on stdin.
# Outputs:
#   The median.
#######################################
median() {
  sort -n | sed -n "$(((RUNS + 1) / 2))p"
}

main() {
  local count modules
  count="$(eval_os 'builtins.length
    (os.pkgs.lib.collect os.pkgs.lib.isOption os.options)')"
  modules="$(eval_os 'builtins.length
    (import (os.pkgs.path + "/nixos/modules/module-list.nix"))')"
  echo "options (lib.collect lib.isOption): ${count}"
  echo "modules in module-list.nix: ${modules}"

  local i start end ms
  local -a times=()
  for ((i = 0; i < RUNS; i++)); do
    start="$(date +%s%N)"
    eval_os 'os.config.system.build.toplevel.drvPath' >/dev/null
    end="$(date +%s%N)"
    ms=$(((end - start) / 1000000))
    times+=("${ms}")
  done
  echo "volatile: toplevel drvPath eval, median of ${RUNS}: $(printf '%s\n' "${times[@]}" | median) ms"
}

main "$@"
