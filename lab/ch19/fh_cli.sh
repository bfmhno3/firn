#!/usr/bin/env bash
#
# The `fh` command line client (0.1.x) against flakehub.com, without logging
# in. HOME is a fresh directory so that fh finds no token of the user. Each
# command prints its exit status and the first lines of its output. The lists
# on FlakeHub change all the time, so every output line is volatile. Commands:
#   fh status                  shows that no token is present
#   fh search firn             full text search
#   fh list releases / versions    read the releases of a public flake
#   fh resolve                 without a token: "output reference ... not found"
# Needs the network.

set -o errexit
set -o nounset
set -o pipefail

readonly LINES_PER_COMMAND=6

#######################################
# Run one fh command and print its status and the head of its output.
# Arguments:
#   fh arguments.
# Outputs:
#   Writes "$ fh ...", "volatile: <line>" and "exit status: N" to stdout.
#######################################
run_fh() {
  local out status=0
  echo "\$ fh $*"
  out="$(timeout 120 fh "$@" 2>&1)" || status=$?
  printf '%s\n' "${out}" | head -n "${LINES_PER_COMMAND}" | cut -c1-160 \
    | sed 's/^/volatile: /'
  echo "exit status: ${status}"
}

main() {
  export HOME="${LAB_TMP}/home"
  mkdir -p "${HOME}"
  unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME

  fh --version
  run_fh status
  run_fh search firn
  run_fh list releases DeterminateSystems/determinate
  run_fh list versions DeterminateSystems/determinate '3.2.*'
  # 没有登录时：FlakeHub 找不到这个输出引用，fh 报 not found（不是认证错误）。
  run_fh resolve \
    'DeterminateSystems/flake-checker/0.1#packages.x86_64-linux.default'
}

main "$@"
