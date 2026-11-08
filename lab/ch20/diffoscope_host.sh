#!/usr/bin/env bash
#
# Compares the two outputs of a non-reproducible build with diffoscope.
# `nix build --rebuild --keep-failed` leaves the second output next to the
# first as `<path>.check`; diffoscope (its `out` output, built from the pinned
# nixpkgs with `nix build -f nix/pkgs.nix diffoscope.out`; nothing
# is installed) then lists the difference. Both builds run in a local store in
# LAB_TMP. diffoscope exits 1 when it finds differences; that is the expected
# result here and a different exit status is an error.

set -o errexit
set -o nounset
set -o pipefail

main() {
  local attr="${FIRN_ROOT}#legacyPackages.x86_64-linux.mini.nondeterministic"
  local store="${LAB_TMP}/store"
  local diffoscope
  diffoscope="$(nix build --no-link --print-out-paths \
    -f "${FIRN_ROOT}/nix/pkgs.nix" diffoscope.out)"

  local out
  out="$(nix build --store "${store}" --no-link --print-out-paths "${attr}")"
  # The rebuild fails by design; --keep-failed keeps the second output.
  nix build --store "${store}" --no-link --rebuild --keep-failed "${attr}" \
    2>&1 | grep -F 'may not be deterministic' | sed 's|^error: ||' \
    | sed "s|${store}||g" || true

  local a="${store}${out}"
  local b="${store}${out}.check"
  if [[ ! -e "${b}" ]]; then
    echo "diffoscope_host.sh: ${b} does not exist" >&2
    return 1
  fi

  local status=0
  # The stamps are random UUIDs; they are replaced so the output is stable.
  "${diffoscope}/bin/diffoscope" "${a}" "${b}" | sed "s|${store}||g" \
    | sed -E 's/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/<uuid>/' \
    || status=$?
  # pipefail makes the status of the pipeline diffoscope's own.
  if ((status != 1)); then
    echo "diffoscope_host.sh: diffoscope exited with ${status}, expected 1" >&2
    return 1
  fi
}

main "$@"
