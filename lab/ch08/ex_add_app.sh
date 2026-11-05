#!/usr/bin/env bash
#
# Exercise answer: add `apps.<system>.mini-wordfreq` for mini.wordfreq in a
# temp copy of the repository and run it with `nix run`. The copy is made from
# the tracked files, so the real flake.nix stays as it is.

set -o errexit
set -o nounset
set -o pipefail

readonly copy="${LAB_TMP}/firn-copy"
mkdir -p "${copy}"
git -C "${FIRN_ROOT}" ls-files -z | (cd "${FIRN_ROOT}" && xargs -0 cp --parents -t "${copy}")
cd "${copy}"
git init --quiet
git add -A

# Insert the new app right after `apps = forAllSystems (system: {`.
sed -i '/^      apps = forAllSystems (system: {$/a\
        mini-wordfreq = {\
          type = "app";\
          program = "${(miniFor system).wordfreq}/bin/wordfreq";\
          meta.description = "Count words on stdin";\
        };' flake.nix
git add flake.nix

echo "== the new apps"
nix flake show --json | jq '.apps."x86_64-linux"'

echo
printf '%s\n' "== printf 'a b a\\nc a b\\n' | nix run .#mini-wordfreq -- 2"
printf 'a b a\nc a b\n' | nix run .#mini-wordfreq -- 2
