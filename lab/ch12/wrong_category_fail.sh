#!/usr/bin/env bash
#
# pkg-config moved from nativeBuildInputs to buildInputs in a copy of
# firn-hello (fixtures/firn_hello_wrong_category.nix), built for aarch64.
# With strictDeps = true the stdenv setup.sh puts only the bin of
# nativeBuildInputs on PATH, so the Makefile's `pkg-config` call prints
# "command not found". Variant 1 keeps package.nix's ZLIB_LIBS=-lz: only the
# --cflags call needs pkg-config, the build still succeeds and the error stays
# buried in the log. Variant 2 drops that workaround: the link has no -lz and fails.
# The lab exits with the status of variant 2.

set -o nounset
set -o pipefail

fixture="${FIRN_ROOT}/lab/ch12/fixtures/firn_hello_wrong_category.nix"
readonly fixture

# Build one variant quietly, print the interesting lines of its build log.
# Arguments:
#   true or false: whether to keep ZLIB_LIBS=-lz.
# Returns:
#   The exit status of nix build.
run_variant() {
  local status
  nix build --no-link --arg keepZlibLibs "$1" --file "${fixture}" 2>/dev/null
  status=$?
  nix log --arg keepZlibLibs "$1" --file "${fixture}" 2>/dev/null \
    | grep -E 'command not found|^aarch64-unknown-linux-gnu-gcc|undefined reference|ld returned' \
    | sed -E 's|/nix/store/[a-z0-9]{32}-||g'
  echo "exit status: ${status}"
  return "${status}"
}

echo "== variant 1: keeps ZLIB_LIBS=-lz"
run_variant true

echo
echo "== variant 2: without ZLIB_LIBS=-lz"
run_variant false
