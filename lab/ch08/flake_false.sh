#!/usr/bin/env bash
#
# `flake = false`: an input that is a plain directory, not a flake. Offline:
# everything is a `path:` flake under LAB_TMP. Prints the lock node, the
# directory listing and a file read through the input, then shows the error
# when the same input is declared without `flake = false`.

set -o errexit
set -o nounset
set -o pipefail

readonly base="${LAB_TMP}/flakefalse"
mkdir -p "${base}/src/sub" "${base}/root" "${base}/root-bad"
echo 'hello from src' >"${base}/src/hello.txt"
echo 'nested' >"${base}/src/sub/inner.txt"

cat >"${base}/root/flake.nix" <<NIX
{
  inputs.src = {
    url = "path:${base}/src";
    flake = false;
  };
  outputs =
    { src, ... }:
    {
      listing = builtins.readDir src;
      hello = builtins.readFile "\${src}/hello.txt";
    };
}
NIX

# The same flake without `flake = false`.
sed '/flake = false;/d' "${base}/root/flake.nix" >"${base}/root-bad/flake.nix"

nix flake lock "path:${base}/root" 2>/dev/null

echo "== nodes.src in flake.lock"
jq '.nodes.src | del(.locked.lastModified, .locked.narHash)' \
  "${base}/root/flake.lock"
echo "root inputs: $(jq -c '.nodes.root.inputs' "${base}/root/flake.lock")"

echo
echo "== nix eval --json .#listing"
nix eval --json "path:${base}/root#listing"

echo
echo "== nix eval --raw .#hello"
nix eval --raw "path:${base}/root#hello"

echo
echo "== without flake = false (first lines of the error)"
status=0
err="$(nix flake lock "path:${base}/root-bad" 2>&1)" || status=$?
sed -n '1,6p' <<<"${err}" \
  | sed -E "s|${base}|\$BASE|g; s|/nix/store/[0-9a-z]{32}-|/nix/store/<hash>-|; s|\?lastModified=[^']*||"
echo "exit status of nix flake lock: ${status}"
