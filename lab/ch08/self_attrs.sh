#!/usr/bin/env bash
#
# The attributes `self` carries, in a temp flake under LAB_TMP: `rev` for a
# clean git tree, `dirtyRev` for a modified one, neither for a plain `path:`
# directory. Commit dates are fixed so the revision is reproducible.

set -o errexit
set -o nounset
set -o pipefail

readonly dir="${LAB_TMP}/selfdemo"
mkdir -p "${dir}"
cd "${dir}"

cat >flake.nix <<'NIX'
{
  outputs =
    { self }:
    {
      info = {
        rev = self.rev or null;
        dirtyRev = self.dirtyRev or null;
        lastModifiedDate = self.lastModifiedDate;
        lastModified = self.lastModified;
        selfOutPath = self.outPath;
      };
    };
}
NIX

export GIT_AUTHOR_DATE='2026-01-02T03:04:05+00:00'
export GIT_COMMITTER_DATE='2026-01-02T03:04:05+00:00'
git init --quiet
git add flake.nix
git -c user.name=firn -c user.email=firn@example.org commit --quiet -m init

# Print the info attrset for a flake reference; the hash of the store path
# changes with every edit, so it is cut out of the output.
show() {
  nix eval --json "$1#info" \
    | jq -c '.selfOutPath |= sub("^/nix/store/[0-9a-z]{32}-"; "/nix/store/<hash>-")'
}

echo "== clean git tree"
show .

echo
echo "== after editing flake.nix (dirty tree)"
echo '# edit' >>flake.nix
show .

echo
echo "== the same directory as a path: flake (git is ignored)"
show "path:${dir}"
