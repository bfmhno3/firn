#!/usr/bin/env bash
#
# What the cc-wrapper does to firn-hello. Inside the build environment
# (`nix develop -f nix/pkgs.nix firn-hello`) NIX_CFLAGS_COMPILE carries the
# greeting macro and the zlib include path, NIX_LDFLAGS the library path, and
# NIX_HARDENING_ENABLE lists the hardening flags the wrapper adds. In the
# result: RUNPATH points into the store (no ld.so.conf), NEEDED shows libz.so.1,
# ldd resolves both libraries in the store, PIE/RELRO/BIND_NOW and the stack
# protector are there. Last, a variant built without ZLIB_LIBS=-lz shows
# zlib.pc listing the static output first, so the link is static and the
# closure loses zlib. Build output paths are store paths, stable for this pin.

set -o errexit
set -o nounset
set -o pipefail

fixtures="${FIRN_ROOT}/lab/ch10/fixtures"
readonly fixtures

pkg="$(nix build --no-link --print-out-paths --file "${FIRN_ROOT}/nix/pkgs.nix" firn-hello)"
readonly pkg
exe="${pkg}/bin/firn-hello"
readonly exe

echo "== patchelf"
echo "interpreter: $(patchelf --print-interpreter "${exe}")"
echo "rpath:"
patchelf --print-rpath "${exe}" | tr ':' '\n' | sed 's/^/  /'
echo "needed:"
patchelf --print-needed "${exe}" | sed 's/^/  /'

echo
echo "== ldd"
ldd "${exe}" | sed 's/ (0x[0-9a-f]*)$//'

echo
echo "== inside the build environment"
# shellcheck disable=SC2016  # the script runs inside the build environment
nix develop --file "${FIRN_ROOT}/nix/pkgs.nix" firn-hello --command bash -c '
  echo "NIX_HARDENING_ENABLE=${NIX_HARDENING_ENABLE}"
  echo "NIX_CFLAGS_COMPILE=${NIX_CFLAGS_COMPILE}" | sed "s/ -frandom-seed=[a-z0-9]*//"
  echo "NIX_LDFLAGS=${NIX_LDFLAGS}" | sed "s|-rpath [^ ]*/outputs/out/lib *||"
  echo "pkg-config --libs zlib:"
  pkg-config --libs zlib | tr " " "\n" | sed "s/^/  /"
'

echo
echo "== hardening in the binary"
readelf -h "${exe}" | grep 'Type:' | sed 's/  */ /g'
readelf -lW "${exe}" | grep -c GNU_RELRO | sed 's/^/GNU_RELRO segments: /'
readelf -d "${exe}" | grep -E 'FLAGS' | sed 's/  */ /g'
readelf -sW "${exe}" | grep -c '__stack_chk_fail' | sed 's/^/__stack_chk_fail symbols: /'

echo
echo "== closure"
nix path-info --recursive --size --human-readable "${pkg}" \
  | sed 's|^/nix/store/[a-z0-9]*-||; s/  */ /g'

echo "closure: $(nix path-info --closure-size --human-readable "${pkg}" | sed 's|^/nix/store/[a-z0-9]*-||; s/  */ /g')"

echo
echo "== variant without ZLIB_LIBS=-lz (zlib.pc order)"
alt="$(nix build --no-link --print-out-paths --file "${fixtures}/firn_hello_default_link.nix")"
readonly alt
echo "needed:"
patchelf --print-needed "${alt}/bin/firn-hello" | sed 's/^/  /'
echo "references:"
nix-store --query --references "${alt}" | sed 's|^/nix/store/[a-z0-9]*-||; s/^/  /' | sort
"${alt}/bin/firn-hello" nix | tail -n 1
