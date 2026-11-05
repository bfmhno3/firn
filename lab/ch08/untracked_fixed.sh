#!/usr/bin/env bash
#
# The same clone as in untracked_invisible_fail.sh, but extra.nix is staged
# with `git add` first (committing is not needed): the eval succeeds.

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=lab/ch08/fixtures/untracked_setup.sh
source "${FIRN_ROOT}/lab/ch08/fixtures/untracked_setup.sh"
setup_clone

echo
echo '== git add extra.nix'
git add extra.nix
git status --short

echo
echo '== nix eval .#extra'
nix eval .#extra
