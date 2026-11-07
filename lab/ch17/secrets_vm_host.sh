#!/usr/bin/env bash
#
# Runs the NixOS VM test checks.x86_64-linux.secrets-vm (sops-nix node versus
# naive node) and prints the `firn: <key> <value>` lines the test script
# reports, plus the wall time. If the test result is already in the store the
# build is forced with --rebuild, otherwise Nix would only print the cached
# result. Host only: needs /dev/kvm.

set -o errexit
set -o nounset
set -o pipefail

readonly ATTR="${FIRN_ROOT}#checks.x86_64-linux.secrets-vm"
readonly LOG="${LAB_TMP}/vm-test.log"

main() {
  local out
  out="$(nix eval --raw "${ATTR}.outPath")"
  local -a flags=(-L --no-link)
  if [[ -e "${out}" ]]; then
    echo "== result already in the store: building with --rebuild"
    flags+=(--rebuild)
  fi
  echo "volatile: /dev/kvm: $([[ -c /dev/kvm ]] && echo present || echo missing)"

  local start end
  start="$(date +%s)"
  nix build "${flags[@]}" "${ATTR}" >"${LOG}" 2>&1 || {
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
  printf '%s\n' "${lines}"
  echo "volatile: wall time: $((end - start)) s"
}

main "$@"
