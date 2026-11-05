#!/usr/bin/env bash
#
# flake.lock taken apart with jq: version, root, the node table, and `locked`
# against `original` for the nixpkgs input.

set -o errexit
set -o nounset
set -o pipefail

readonly lock="${FIRN_ROOT}/flake.lock"

echo "== top-level keys"
jq -c 'keys' "${lock}"
echo "version: $(jq .version "${lock}")"

echo
echo "== root"
jq -r '.root' "${lock}"

echo
echo "== nodes"
jq -c '.nodes | keys' "${lock}"
echo "node count: $(jq '.nodes | length' "${lock}")"

echo
echo "== nodes.root: the inputs of the top-level flake (name -> node)"
jq -c '.nodes.root' "${lock}"

echo
echo "== nodes.nixpkgs.original: what flake.nix asked for"
jq '.nodes.nixpkgs.original' "${lock}"

echo
echo "== nodes.nixpkgs.locked: what was pinned"
jq '.nodes.nixpkgs.locked' "${lock}"

echo
echo "== keys only in locked"
jq -c '(.nodes.nixpkgs.locked | keys) - (.nodes.nixpkgs.original | keys)' \
  "${lock}"
