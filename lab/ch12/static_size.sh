#!/usr/bin/env bash
#
# Binary size and closure size of firn-hello built three ways: glibc dynamic,
# pkgsStatic (musl, static) and pkgsMusl (musl, dynamic). Sizes are in bytes
# from `stat` and `nix path-info --closure-size`; paths counts the closure.
# The static binary has no runtime library and `ldd` says so, yet its closure
# still lists zlib: the static stdenv (pkgs/stdenv/cross/default.nix picks
# stdenvAdapters.makeStatic, whose propagateBuildInputs adapter turns
# buildInputs into propagatedBuildInputs) records zlib in nix-support, which
# the reference scanner then sees. The last section prints that file.

set -o errexit
set -o nounset
set -o pipefail

strip_hash() {
  sed -E 's|/nix/store/[a-z0-9]{32}-||g'
}

printf '%-18s %10s %12s %6s\n' package binary closure paths
for name in firn-hello firn-hello-musl firn-hello-static; do
  out="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#${name}" 2>/dev/null)"
  bin="${out}/bin/firn-hello"
  size="$(stat --format=%s "${bin}")"
  closure="$(nix path-info --closure-size "${out}" | awk '{ print $2 }')"
  count="$(nix path-info --recursive "${out}" | wc -l)"
  printf '%-18s %10d %12d %6d\n' "${name}" "${size}" "${closure}" "${count}"
done

out="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#firn-hello-static" 2>/dev/null)"
echo
echo "== ldd of the static build"
ldd "${out}/bin/firn-hello" 2>&1 || true
echo "== references of the static build"
nix-store --query --references "${out}" | strip_hash
echo "== nix-support/propagated-build-inputs of the static build"
strip_hash <"${out}/nix-support/propagated-build-inputs"
