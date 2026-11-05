#!/usr/bin/env bash
#
# Exercise answer: pkgsCross.mingwW64.firn-hello. It fails twice, for two
# different reasons, and both are real errors of this pin:
#   1. meta.platforms = lib.platforms.unix refuses x86_64-windows at
#      evaluation time (nothing is built);
#   2. with meta.platforms widened, gcc writes firn-hello.exe but the Makefile
#      installs firn-hello, so installPhase fails (`install: cannot stat`).
# Step 3 installs the .exe by hand and runs `file` on it. The package itself
# (pkgs/firn-hello/package.nix) is not changed: the exercise adjusts a copy
# through overrideAttrs.

set -o nounset
set -o pipefail

strip_hash() {
  sed -E 's|/nix/store/[a-z0-9]{32}-||g'
}

cat >"${LAB_TMP}/plain.nix" <<NIX
(import ${FIRN_ROOT}/nix/pkgs.nix { }).pkgsCross.mingwW64.firn-hello
NIX

cat >"${LAB_TMP}/platforms.nix" <<NIX
let
  pkgs = import ${FIRN_ROOT}/nix/pkgs.nix { };
in
pkgs.pkgsCross.mingwW64.firn-hello.overrideAttrs (old: {
  meta = old.meta // { platforms = pkgs.lib.platforms.all; };
})
NIX

cat >"${LAB_TMP}/exe.nix" <<NIX
let
  pkgs = import ${FIRN_ROOT}/nix/pkgs.nix { };
in
pkgs.pkgsCross.mingwW64.firn-hello.overrideAttrs (old: {
  meta = old.meta // { platforms = pkgs.lib.platforms.all; };
  installPhase = ''
    runHook preInstall
    install -D -m 755 firn-hello.exe "\$out/bin/firn-hello.exe"
    runHook postInstall
  '';
})
NIX

echo "== 1. as packaged"
nix build --no-link --file "${LAB_TMP}/plain.nix" 2>&1 \
  | grep -E 'Refusing to evaluate|hostPlatform.system' | strip_hash \
  | sed -E "s|${FIRN_ROOT}|<firn>|; s/^ +//"
echo

echo "== 2. meta.platforms widened"
nix build --no-link --file "${LAB_TMP}/platforms.nix" 2>&1 \
  | grep -E 'x86_64-w64-mingw32-gcc|cannot stat|^ *> make' | strip_hash \
  | sed -E 's/^ *> //; s|-I[^ ]*/include ||' | sort -u
echo

echo "== 3. install the .exe by hand"
if out="$(nix build --no-link --print-out-paths --file "${LAB_TMP}/exe.nix" 2>/dev/null)"; then
  ls "${out}/bin"
  file --brief "${out}/bin/firn-hello.exe"
else
  echo "build failed"
  exit 1
fi
