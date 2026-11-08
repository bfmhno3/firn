#!/usr/bin/env bash
#
# A flake's source is copied to the store before evaluation: only the
# git-tracked files, as one `/nix/store/<hash>-source`. Prints the store path,
# its size and file count next to the working directory, then checks whether
# this Nix has a `lazy-trees` setting (a preview of post 19).

set -o errexit
set -o nounset
set -o pipefail

# `flake prefetch` copies the source into the store on every Nix version:
# since 2.35 `flake metadata` alone leaves the path virtual (not in the store).
store_path="$(nix flake prefetch --json "${FIRN_ROOT}" | jq -r .storePath)"
readonly store_path

echo "== the copy"
echo "path:  ${store_path/\/nix\/store\/*-/\/nix\/store\/<hash>-}"
echo "size:  $(du -sh "${store_path}" | cut -f1)"
echo "bytes: $(du -sb "${store_path}" | cut -f1)"
echo "files: $(find "${store_path}" -type f | wc -l)"

echo
echo "== the same repository in the working directory"
echo "tracked files: $(git -C "${FIRN_ROOT}" ls-files | wc -l)"
echo "du -sh whole directory (with .git, out/, result): $(du -sh "${FIRN_ROOT}" | cut -f1)"
echo "du -sh .git: $(du -sh "${FIRN_ROOT}/.git" | cut -f1)"

echo
echo "== top level of the copy (no .git, no out/)"
ls -A "${store_path}"

echo
echo "== lazy trees"
nix --version
if nix config show lazy-trees 2>&1; then
  echo "this Nix has a lazy-trees setting"
else
  echo "(no such setting in this Nix; Determinate Nix has it: post 19)"
fi
