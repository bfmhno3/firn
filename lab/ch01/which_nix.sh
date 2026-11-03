#!/usr/bin/env bash
#
# Shows which Nix this shell runs and what the language reports about itself.

set -o errexit
set -o nounset
set -o pipefail

nix --version
readlink -f "$(command -v nix)"
nix eval --expr 'builtins.nixVersion'
nix eval --expr 'builtins.langVersion'
