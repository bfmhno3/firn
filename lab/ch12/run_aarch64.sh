#!/usr/bin/env bash
#
# Run the aarch64 build of firn-hello on this x86_64 machine through
# qemu-user (`qemu-aarch64` from the pinned nixpkgs' qemu). The output must
# equal the native build's output. stdenv skips doInstallCheck when the build
# machine cannot execute the host platform's binaries (make-derivation.nix:
# doInstallCheck && canExecuteHostOnBuild), so the cross build never ran
# firn-hello itself; the last lines show the flag on both derivations.

set -o errexit
set -o nounset
set -o pipefail

qemu="$(nix build --no-link --print-out-paths --file "${FIRN_ROOT}/nix/pkgs.nix" qemu)"
readonly qemu
cross="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#firn-hello-aarch64")"
readonly cross
native="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#firn-hello")"
readonly native

echo "== qemu-aarch64 firn-hello nix"
"${qemu}/bin/qemu-aarch64" "${cross}/bin/firn-hello" nix | tee "${LAB_TMP}/cross.txt"

echo
echo "== native firn-hello nix"
"${native}/bin/firn-hello" nix | tee "${LAB_TMP}/native.txt"

echo
if diff -u "${LAB_TMP}/native.txt" "${LAB_TMP}/cross.txt"; then
  echo "outputs are identical"
else
  echo "outputs differ"
  exit 1
fi

echo
echo "== direct execution without qemu"
bash -c "\"\$1\" nix" bash "${cross}/bin/firn-hello" 2>&1 \
  | sed -E 's|/nix/store/[a-z0-9]{32}-||g; s|^bash: line [0-9]+: |bash: |' || true

echo
echo "== doInstallCheck in the derivation"
for attr in firn-hello firn-hello-aarch64; do
  echo "${attr}: $(nix eval --json "${FIRN_ROOT}#packages.x86_64-linux.${attr}.doInstallCheck" 2>/dev/null)"
done
