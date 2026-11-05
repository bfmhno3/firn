#!/usr/bin/env bash
#
# GitHub's tarball bytes and the unpacked tree have different hashes: the
# first is a sha256 of the .tar.gz file (what fetchurl checks, "flat"), the
# second is a sha256 of the NAR serialisation of the directory (what
# fetchFromGitHub checks, "nar"). fetchFromGitHub hashes the tree because
# the tarball bytes depend on how GitHub's tar and gzip happen to produce
# them, while the tree depends only on the files. Everything happens in
# LAB_TMP; needs github.com and says so when it is unreachable.

set -o errexit
set -o nounset
set -o pipefail

readonly url=https://github.com/bfmhno3/cairn/archive/refs/tags/ch10.tar.gz

if ! curl --silent --location --max-time 60 --fail --output cairn.tar.gz "${url}"; then
  echo "offline: ${url} unreachable, skipping; the pinned hashes are in fixtures/fetchers.nix"
  exit 0
fi

echo "== bytes of the tarball"
wc -c <cairn.tar.gz | sed 's/^/size: /'
echo "sha256sum:      $(sha256sum cairn.tar.gz | cut -d' ' -f1)"
echo "nix hash file:  $(nix hash file --type sha256 --sri cairn.tar.gz)"

echo
echo "== NAR hash of the unpacked tree"
mkdir tree
tar --extract --gzip --file cairn.tar.gz --directory tree --strip-components=1
echo "nix hash path:  $(nix hash path --type sha256 --sri tree)"

echo
echo "== what the fetchers check"
for attr in tarball fromGitHub; do
  drv="$(nix eval --raw --file "${FIRN_ROOT}/lab/ch10/fixtures/fetchers.nix" "${attr}.drvPath")"
  nix derivation show "${drv}" \
    | jq -r --arg attr "${attr}" '.derivations[].outputs.out | "\($attr): \(.method) \(.hash)"'
done
