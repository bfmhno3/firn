#!/usr/bin/env bash
#
# A profile is a chain of symlinks. This builds one under LAB_TMP (never the
# user's profile): add hello, add jq (`nix profile add` is the Nix 2.34 name of
# `nix profile install`, which still works but warns), look at the history, roll back,
# and compare closures. The generation links are `prof-<N>-link`, and `prof`
# points at the current one. Store hashes are stable for the pinned nixpkgs;
# the temp directory is printed as <LAB_TMP>. `nix profile history` prints
# dates for the generations, which differ per run, so they are masked as
# <date>. Fetch messages from a cold cache are dropped (stderr is hidden).

set -o errexit
set -o nounset
set -o pipefail

readonly prof="${LAB_TMP}/prof"
readonly pkgs="${FIRN_ROOT}/nix/pkgs.nix"

#######################################
# Replace the temp directory and ANSI colors in a stream.
#######################################
tidy() {
  sed -e "s|${LAB_TMP}|<LAB_TMP>|g" \
    -e 's/\x1b\[[0-9;]*m//g' \
    -e 's/[0-9]\{4\}-[0-9][0-9]-[0-9][0-9]/<date>/g'
}

#######################################
# Print the generation symlinks of the profile.
#######################################
show_links() {
  # shellcheck disable=SC2012  # `ls -l` shows the links, as the post does
  (cd "${LAB_TMP}" \
    && ls -l prof prof-*-link | awk '{print $9, $10, $11}' | sed 's|/nix/store/[a-z0-9]*-|/nix/store/<hash>-|')
}

echo "== nix profile add (the old name was install) hello, then jq"
nix profile add --profile "${prof}" -f "${pkgs}" hello 2>/dev/null
nix profile add --profile "${prof}" -f "${pkgs}" jq 2>/dev/null

echo
echo "== generation symlinks"
show_links

echo
echo "== nix profile list"
nix profile list --profile "${prof}" | tidy | grep -E '^(Name|Store paths|Flake)' || true

echo
echo "== nix profile history"
nix profile history --profile "${prof}" | tidy

echo
echo "== nix profile rollback"
nix profile rollback --profile "${prof}" 2>&1 | tidy
show_links
echo "hello present: $(test -x "${prof}/bin/hello" && echo yes || echo no)"
echo "jq present:    $(test -x "${prof}/bin/jq" && echo yes || echo no)"

echo
echo "== nix profile diff-closures (hello only -> hello + jq)"
nix profile diff-closures --profile "${prof}" | tidy
