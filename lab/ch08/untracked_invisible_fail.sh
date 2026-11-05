#!/usr/bin/env bash
#
# Flakes only see git-tracked files. In a clone, flake.nix imports ./extra.nix,
# but extra.nix was never `git add`ed: `nix eval` cannot find it. The script
# prints the error and exits 1.

set -o nounset
set -o pipefail

# shellcheck source=lab/ch08/fixtures/untracked_setup.sh
source "${FIRN_ROOT}/lab/ch08/fixtures/untracked_setup.sh"
setup_clone || exit 1

echo
echo '== nix eval .#extra'
if nix eval .#extra 2>&1; then
  echo 'unexpected: eval succeeded' >&2
  exit 0
fi
exit 1
