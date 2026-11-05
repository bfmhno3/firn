#!/usr/bin/env bash
#
# Host only. How much would a garbage collection reclaim? Two read-only
# answers: `nix store gc --dry-run` prints how many store paths are dead, and
# `nix-store --gc --print-dead` lists them, so their NAR sizes can be added up
# with `nix path-info`. Nothing is deleted. All numbers are volatile: they
# describe this machine today. (Side effect worth knowing: while it scans the
# roots, nix removes stale links under /nix/var/nix/gcroots/auto, links whose
# target no longer exists. Those are not roots anyway.)

set -o errexit
set -o nounset
set -o pipefail

echo "== nix store gc --dry-run"
echo "volatile: $(nix store gc --dry-run 2>&1 | tail -n 1)"

dead="${LAB_TMP}/dead.txt"
readonly dead
nix-store --gc --print-dead 2>/dev/null >"${dead}"

echo
echo "== nix-store --gc --print-dead | wc -l"
echo "volatile: $(wc -l <"${dead}") lines"

# `.lock` files and half-built outputs are listed as dead but are not valid
# store paths, so path-info cannot size them. xargs splits the list into
# several path-info calls; `jq -s` adds their answers up.
echo
echo "== dead paths that path-info can size"
grep -v '\.lock$' "${dead}" \
  | xargs nix path-info --json --json-format 1 2>/dev/null \
  | jq -s -r '[.[] | to_entries[] | .value.narSize] | "volatile: \(length) valid paths, \(add / 1048576 | floor) MiB"'
