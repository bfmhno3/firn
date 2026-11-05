#!/usr/bin/env bash
#
# Host only, read-only. `nh` is a friendlier front end for the same Nix
# commands. Two subcommands that change nothing: `nh search` queries
# search.nixos.org (needs a network; the five-line excerpt is volatile), and
# `nh clean user --dry` prints which generations of the user's profiles it
# *would* delete and which it keeps. `--no-gc` and `--no-gcroots` keep the dry
# run to profile links; `--dry` means nothing is removed. flags checked with
# `nh clean user --help` (nh 4.4.2).

set -o errexit
set -o nounset
set -o pipefail

echo "volatile: == nh search --limit 3 hello (names only)"
nh search --limit 3 hello 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E '^[A-Za-z.]+ \('

echo
echo "volatile: == nh clean user --dry --no-gc --no-gcroots --keep 3 (excerpt)"
nh clean user --dry --no-gc --no-gcroots --keep 3 2>&1 \
  | sed -e 's/\x1b\[[0-9;]*m//g' -e "s|${HOME}|~|" \
  | grep -E '^(Keeping|- (OK|DEL))'
