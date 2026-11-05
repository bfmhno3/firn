#!/usr/bin/env bash
#
# Preview of post 14: nixpkgs puts a package under pkgs/by-name/<xx>/<name>/
# where <xx> is the first two letters of the name, lower case, and the file
# is package.nix; callPackage is applied automatically. Shows where `hello`
# lives in the pinned nixpkgs, how many packages already use the layout, and
# that the shard rule holds for every one of them.

set -o errexit
set -o nounset
set -o pipefail

nixpkgs="$(nix eval --raw --file "${FIRN_ROOT}/nix/pins.nix" nixpkgs)"
readonly nixpkgs
by_name="${nixpkgs}/pkgs/by-name"
readonly by_name

echo "== where hello is defined (meta.position)"
nix eval --raw --file "${FIRN_ROOT}/nix/pkgs.nix" hello.meta.position \
  | sed "s|^${nixpkgs}/||"
echo

echo "== files of pkgs/by-name/he/hello"
ls "${by_name}/he/hello"

echo
echo "== shard rule: <xx> = first two letters of the name, lower case"
total=0
bad=0
for dir in "${by_name}"/*/*/; do
  shard="$(basename "$(dirname "${dir}")")"
  name="$(basename "${dir}")"
  total=$((total + 1))
  expected="$(tr '[:upper:]' '[:lower:]' <<<"${name:0:2}")"
  if [[ "${shard}" != "${expected}" ]]; then
    bad=$((bad + 1))
  fi
done
echo "volatile: ${total} package directories under pkgs/by-name at this pin"
echo "directories that break the shard rule: ${bad}"
