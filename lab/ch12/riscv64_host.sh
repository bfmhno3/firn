#!/usr/bin/env bash
#
# pkgsCross.riscv64.firn-hello: a second cross target without any change to
# the package. The cross toolchain comes from the binary cache; the lab
# prints the wall time of the build (volatile) and the build plan, so the
# post can say whether a toolchain was built or substituted. Host only:
# on a cold store nix fetched 130.6 MiB (15 paths) and built only firn-hello
# itself; on a warm store the build plan is empty and prints nothing.

set -o errexit
set -o nounset
set -o pipefail

attr=pkgsCross.riscv64.firn-hello
readonly attr

echo "== build plan (derivations to build, paths to fetch)"
nix build --dry-run --no-link --file "${FIRN_ROOT}/nix/pkgs.nix" "${attr}" 2>&1 \
  | { grep -E '^this|^these' || true; } | sed -E 's/ \(.*\)//; s/^/volatile: /'

start="$(date +%s%N)"
out="$(nix build --no-link --print-out-paths --file "${FIRN_ROOT}/nix/pkgs.nix" "${attr}" 2>/dev/null)"
end="$(date +%s%N)"
echo "volatile: build wall time $(((end - start) / 1000000)) ms"

echo
echo "== file"
file --brief "${out}/bin/firn-hello" | sed -E 's|/nix/store/[a-z0-9]{32}-||g; s/, BuildID\[sha1\]=[0-9a-f]+//'

echo
echo "== qemu-riscv64 firn-hello nix"
qemu="$(nix build --no-link --print-out-paths --file "${FIRN_ROOT}/nix/pkgs.nix" qemu)"
"${qemu}/bin/qemu-riscv64" "${out}/bin/firn-hello" nix
