#!/usr/bin/env bash
#
# `meta` of firn-hello as JSON, and `nix log` of its build: the phases that
# ran, the compiler line (-DFIRN_GREETING comes from NIX_CFLAGS_COMPILE, not
# from the command line, so the gcc line does not show it; -lz is the
# ZLIB_LIBS override from package.nix), and what fixupPhase did to the ELF
# file. The log of a derivation built on this machine is kept by the daemon;
# a derivation that came from a binary cache has no log and the lab says so.

set -o errexit
set -o nounset
set -o pipefail

pkgs_nix="${FIRN_ROOT}/nix/pkgs.nix"
readonly pkgs_nix

echo "== meta"
nix eval --json --file "${pkgs_nix}" firn-hello.meta | jq --sort-keys .

echo
echo "== build"
out="$(nix build --no-link --print-out-paths --file "${pkgs_nix}" firn-hello)"
readonly out

echo "== nix log: phases and the lines that matter"
if ! log="$(nix log --file "${pkgs_nix}" firn-hello 2>/dev/null)"; then
  echo "no build log: this derivation was substituted, not built here"
  exit 0
fi
readonly log
# shellcheck disable=SC2001  # a regex is needed to drop the colour codes
sed 's/\x1b\[[0-9;]*m//g' <<<"${log}" \
  | grep -E '^(Running phase|gcc |install -D|shrinking /|stripping )' \
  | sed "s|${out}|<out>|g; s|/nix/store/[a-z0-9]*-zlib-[0-9.]*-dev|<zlib-dev>|g"
