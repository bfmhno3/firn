#!/usr/bin/env bash
#
# Exercise: can nix-update bump cairn, whose tags are chNN, not versions?
# Runs `nix-update cairn --version-regex 'ch(.*)'` on a throwaway git
# worktree of firn-cairn under LAB_TMP (nix-update edits package.nix in
# place; there is no dry-run flag, so the lab diffs the file afterwards and
# throws the worktree away). It reads the release feed of the cairn repo and
# prefetches the new source; read-only network use. It writes the
# digits of the newest tag as the version, not 0.1.0 (see the diff). Host only.

set -o errexit
set -o nounset
set -o pipefail

FIRN_NIXPKGS="${FIRN_NIXPKGS:-${HOME}/.cache/firn/nixpkgs}"
export FIRN_NIXPKGS
bash "${FIRN_ROOT}/scripts/nixpkgs-worktree.sh" >/dev/null 2>&1

tree="${LAB_TMP}/update"
git -C "${FIRN_NIXPKGS}" worktree add --detach "${tree}" firn-cairn >/dev/null 2>&1
trap 'git -C "${FIRN_NIXPKGS}" worktree remove --force "${tree}"' EXIT
cd "${tree}"

echo "== nix-update --help (the flags used below)"
nix-update --help | grep -E -- '-vr|--version-regex|--version \[|--commit'

echo
echo "== nix-update cairn --version-regex 'ch(.*)'"
status=0
nix-update cairn --version-regex 'ch(.*)' 2>&1 | grep -v '^\$ ' \
  | sed -E "s|${tree}|<worktree>|g"
status="${PIPESTATUS[0]}" || true
echo "exit status: ${status}"

echo
echo "== git diff"
git diff

echo
echo "== nix-build -A cairn.tests.version (after the bump)"
status=0
log="$(nix-build -A cairn.tests.version --no-out-link 2>&1)" || status=$?
grep -E '^Version string|^cairn |^error: Cannot build|Reason' <<<"${log}" \
  | sed -E 's|/nix/store/[a-z0-9]{32}-||g'
echo "exit status: ${status}"

echo
echo "== why"
cat <<'TEXT'
nix-update does not fail: it takes the first capture group of the newest
tag (ch10) as the version and writes version = "10". src.tag is the literal
"ch10", so the source and the hash do not change. The package now claims a
version that `cairn --version` (0.1.0) contradicts, and
passthru.tests.version, which uses testVersion's defaults (the package's own
version and `--version`), fails with: Version string '10' not found!
nix-update expects a tag derived from the version, such as
tag = "v${finalAttrs.version}" with upstream tags like v0.1.0.
TEXT
