#!/usr/bin/env bash
#
# In pure evaluation mode an unpinned fetcher is refused: the URL alone does
# not determine the content, so the evaluation would not be reproducible.

set -o errexit
set -o nounset
set -o pipefail

nix eval --pure-eval --expr \
  'builtins.fetchTarball "https://github.com/bfmhno3/cairn/archive/refs/tags/ch10.tar.gz"'
