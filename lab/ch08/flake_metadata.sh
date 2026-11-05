#!/usr/bin/env bash
#
# What `nix flake metadata --json` says about the locked nixpkgs input: the
# revision, the narHash and lastModified (a Unix timestamp) as a UTC date.

set -o errexit
set -o nounset
set -o pipefail

json="$(nix flake metadata --json "${FIRN_ROOT}")"
readonly json

echo "== locked nixpkgs"
jq -r '.locks.nodes.nixpkgs.locked
  | "rev:          \(.rev)",
    "narHash:      \(.narHash)",
    "lastModified: \(.lastModified) = \(.lastModified | todate)"' <<<"${json}"

echo
echo "== original (what flake.nix asked for)"
jq -c '.locks.nodes.nixpkgs.original' <<<"${json}"

echo
echo "== the keys of the whole report"
jq -c 'keys' <<<"${json}"
