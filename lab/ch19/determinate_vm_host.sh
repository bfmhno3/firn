#!/usr/bin/env bash
#
# Runs the NixOS VM test checks.x86_64-linux.determinate-vm of
# experiments/determinate (Determinate Nix's NixOS module in a VM: version,
# nix.conf, determinate-nixd, lazy trees, parallel evaluation) and prints the
# `firn: <key> <value>` lines the test script reports, plus the wall time.
# Timing lines are marked volatile. The two options are the flake's nixConfig;
# a flake's nixConfig is ignored for untrusted settings unless
# --accept-flake-config is given, so they are passed on the command line.
# If the result is already in the store the build is forced with --rebuild,
# otherwise Nix would only print the cached result. Host only: needs /dev/kvm
# and the network (Determinate Nix comes from install.determinate.systems).

set -o errexit
set -o nounset
set -o pipefail

readonly FLAKE="${FIRN_ROOT}/experiments/determinate"
readonly ATTR="${FLAKE}#checks.x86_64-linux.determinate-vm"
readonly LOG="${LAB_TMP}/vm-test.log"
readonly -a OPTIONS=(
  --option extra-substituters https://install.determinate.systems
  --option extra-trusted-public-keys
  cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=
)

main() {
  local out
  out="$(nix eval --raw "${ATTR}.outPath" "${OPTIONS[@]}")"
  local -a flags=(-L --no-link)
  if [[ -e "${out}" ]]; then
    echo "== result already in the store: building with --rebuild"
    flags+=(--rebuild)
  fi
  local kvm=missing
  [[ -c /dev/kvm ]] && kvm=present
  echo "volatile: /dev/kvm: ${kvm}"

  local start end
  start="$(date +%s)"
  nix build "${flags[@]}" "${ATTR}" "${OPTIONS[@]}" >"${LOG}" 2>&1 || {
    tail -n 40 "${LOG}" >&2
    return 1
  }
  end="$(date +%s)"

  echo "== lines printed by the test script"
  local lines
  lines="$(grep -o 'firn: .*' "${LOG}" | awk '!seen[$0]++')"
  if [[ -z "${lines}" ]]; then
    echo "no firn: lines in the build log" >&2
    return 1
  fi
  # 带 ms 的行是计时，加上 volatile: 前缀。
  printf '%s\n' "${lines}" | sed -E 's/^(firn: .*_ms .*)$/volatile: \1/'
  echo "volatile: wall time: $((end - start)) s"
}

main "$@"
