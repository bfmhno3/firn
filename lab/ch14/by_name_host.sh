#!/usr/bin/env bash
#
# Counts pkgs/by-name in the pinned nixpkgs and checks the shard rule of
# RFC 140: a package named <name> lives in pkgs/by-name/<xx>/<name>/ where
# <xx> is the lowercase two-letter prefix of <name> (the whole name when it has
# one character). Exits 1 if any package
# directory breaks the rule. Host only: needs the worktree from
# worktree_host.sh.

set -o errexit
set -o nounset
set -o pipefail

FIRN_NIXPKGS="${FIRN_NIXPKGS:-${HOME}/.cache/firn/nixpkgs}"
export FIRN_NIXPKGS
bash "${FIRN_ROOT}/scripts/nixpkgs-worktree.sh" >/dev/null 2>&1
cd "${FIRN_NIXPKGS}"

echo "== ls pkgs/by-name | wc -l (entries of by-name, README.md included)"
# shellcheck disable=SC2012 # plain `ls | wc -l`; find counts 758 shards (no README.md)
ls pkgs/by-name | wc -l

echo
echo "== shard directories"
find pkgs/by-name -mindepth 1 -maxdepth 1 -type d | wc -l

echo
echo "== package directories (pkgs/by-name/*/*/)"
find pkgs/by-name -mindepth 2 -maxdepth 2 -type d | wc -l

echo
echo "== package directories whose shard is not lowercase(first two letters)"
bad=0
while IFS= read -r dir; do
  shard="${dir#pkgs/by-name/}"
  shard="${shard%%/*}"
  name="${dir##*/}"
  prefix="${name:0:2}"
  if [[ "${shard}" != "${prefix,,}" ]]; then
    echo "BAD ${dir}"
    bad=$((bad + 1))
  fi
done < <(find pkgs/by-name -mindepth 2 -maxdepth 2 -type d | LC_ALL=C sort)
echo "violations: ${bad}"

echo
echo "== the shard of cairn, and two shards that start with an underscore"
ls -d pkgs/by-name/ca/cairn
printf '%s\n' pkgs/by-name/_0/* | head -n 3

echo
echo "== names of one character (their shard is the whole name, lowercased)"
find pkgs/by-name -mindepth 2 -maxdepth 2 -type d -name '?' | LC_ALL=C sort

((bad == 0))
