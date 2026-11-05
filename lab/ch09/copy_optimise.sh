#!/usr/bin/env bash
#
# `nix copy` moves a closure between stores; `nix store optimise` hard-links
# identical files inside one store. Both run against throwaway stores under
# LAB_TMP (a local store rooted there, and a file:// binary cache), never the
# host's. First `mini.hello` is copied to the local store (3 paths: hello,
# greeting, busybox) and to a binary cache (one .narinfo per path plus the
# .nar files). Then two text files with the same content but different names
# become two store paths with two inodes; `optimise` makes them one inode.
# The narinfo URL and hashes depend on the xz compressor and are fixed for
# this Nix version; the number of files `optimise` links includes the files
# of the copied closure, so it is printed as volatile.

set -o errexit
set -o nounset
set -o pipefail

readonly store="${LAB_TMP}/store"
readonly cache="${LAB_TMP}/cache"

hello="$(nix-build "${FIRN_ROOT}" -A mini.hello --no-out-link)"
readonly hello

echo "== nix copy --to <local store>"
nix copy --no-check-sigs --to "${store}" "${hello}" 2>&1 | sed "s|to '.*'|to '<store>'|; s|/nix/store/[a-z0-9]*-|/nix/store/<hash>-|"
echo "paths in the target store:"
nix path-info --recursive --store "${store}" "${hello}" | sed 's|/nix/store/[a-z0-9]*-|/nix/store/<hash>-|'

echo
echo "== nix copy --to file://<cache>"
nix copy --no-check-sigs --to "file://${cache}" "${hello}" 2>/dev/null
echo "narinfo files: $(find "${cache}" -name '*.narinfo' | wc -l)"
echo "nar files:     $(find "${cache}/nar" -type f | wc -l)"
echo "cache entry of hello:"
sed -n '1,4p' "${cache}/$(basename "${hello}" | cut -d- -f1).narinfo"

echo
echo "== nix store optimise"
printf 'same content\n%.0s' {1..2000} >f1
cp f1 f2
a="$(nix store add --store "${store}" f1)"
b="$(nix store add --store "${store}" f2)"
readonly a b
inodes() {
  stat -c '%i' "${store}${a}" "${store}${b}" | sort -u | wc -l
}
echo "distinct inodes of the two files before: $(inodes)"
nix store optimise --store "${store}" 2>&1 | sed 's/^.* freed/volatile: freed/'
echo "distinct inodes of the two files after:  $(inodes)"
echo "link count after: $(stat -c '%h' "${store}${a}") (two store paths and one entry in .links)"
