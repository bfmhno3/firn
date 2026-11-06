#!/usr/bin/env bash
#
# `nix print-dev-env` turns a dev shell into a bash script that anyone can
# `source`. Prints its size, its first and last line, the names of the bash
# functions it declares (stdenv's setup script is inlined, so the phase
# functions are there), and the line of nix's get-env.sh that sources
# $stdenv/setup: that is how `nix develop` gets those functions, by running
# the shell derivation's setup in a throwaway build and dumping the result.
# Sizes and counts are volatile.

set -o errexit
set -o nounset
set -o pipefail

readonly SHELL_ATTR="${FIRN_ROOT}#devShells.x86_64-linux.c"

main() {
  local script="${LAB_TMP}/dev-env.sh"
  nix print-dev-env "${SHELL_ATTR}" >"${script}" 2>/dev/null

  printf 'volatile: lines %d\n' "$(wc -l <"${script}")"
  echo "first line: $(head -n 1 "${script}")"
  echo "last line:  $(grep -v '^$' "${script}" | tail -n 1)"

  # 在子 shell 里 source，再用 declare -F 列出函数名。
  local names
  names="$(bash -c 'source "$1"; declare -F' _ "${script}" \
    | awk '{ print $3 }')"
  printf 'volatile: declared functions %d\n' "$(wc -l <<<"${names}")"
  echo "== phase functions"
  grep 'Phase$' <<<"${names}" | sort
  echo "== other well-known functions"
  grep -x -e runHook -e runPhase -e genericBuild -e patchShebangs \
    -e stripHash -e substituteInPlace <<<"${names}" | sort

  echo "== the line that sources setup"
  local env_drv get_env
  env_drv="$(nix print-dev-env -vvv "${SHELL_ATTR}" 2>&1 >/dev/null \
    | grep -o '/nix/store/[a-z0-9]*-nix-shell-env.drv' | sort -u)"
  get_env="$(nix derivation show "${env_drv}" 2>/dev/null \
    | jq -r '.derivations | to_entries[0].value.args[0]')"
  # shellcheck disable=SC2016  # $stdenv is literal text in get-env.sh
  grep -n 'source "$stdenv"/setup' "${get_env}"
}

main "$@"
