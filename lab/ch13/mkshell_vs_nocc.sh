#!/usr/bin/env bash
#
# mkShell against mkShellNoCC with the same packages (hello, jq), see
# fixtures/shells.nix. mkShell is stdenv.mkDerivation, so its build inputs
# include the C compiler wrapper and binutils; mkShellNoCC is
# stdenvNoCC.mkDerivation and leaves them out. For both shell derivations the
# lab prints the closure size and path count of the shell output, and the
# store paths that only the mkShell closure has. Sizes and counts are volatile.

set -o errexit
set -o nounset
set -o pipefail

readonly FIXTURE="${FIRN_ROOT}/lab/ch13/fixtures/shells.nix"

strip_hash() {
  sed -E 's|/nix/store/[a-z0-9]{32}-||g'
}

main() {
  local with_cc no_cc
  with_cc="$(nix build --no-link --print-out-paths \
    --file "${FIXTURE}" withCc 2>/dev/null)"
  no_cc="$(nix build --no-link --print-out-paths \
    --file "${FIXTURE}" noCc 2>/dev/null)"

  local name out size count
  printf '%-8s %14s %6s\n' shell closure paths
  for name in withCc noCc; do
    out="${with_cc}"
    [[ "${name}" == noCc ]] && out="${no_cc}"
    size="$(nix path-info --closure-size "${out}" | awk '{ print $2 }')"
    count="$(nix-store --query --requisites "${out}" | wc -l)"
    printf 'volatile: %-8s %14d %6d\n' "${name}" "${size}" "${count}"
  done

  echo
  echo "== paths only in the mkShell closure"
  comm -23 \
    <(nix-store --query --requisites "${with_cc}" | strip_hash | sort) \
    <(nix-store --query --requisites "${no_cc}" | strip_hash | sort)
  echo "== paths only in the mkShellNoCC closure"
  comm -13 \
    <(nix-store --query --requisites "${with_cc}" | strip_hash | sort) \
    <(nix-store --query --requisites "${no_cc}" | strip_hash | sort)
}

main "$@"
