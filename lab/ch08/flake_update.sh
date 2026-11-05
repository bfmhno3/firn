#!/usr/bin/env bash
#
# `nix flake lock` keeps existing pins; only `nix flake update` moves them.
# Offline: a leaf flake c and a root flake with a `path:` input on it, both
# under LAB_TMP. The narHash of c is printed after each step.

set -o errexit
set -o nounset
set -o pipefail

readonly base="${LAB_TMP}/update"
mkdir -p "${base}/c" "${base}/root"

cat >"${base}/c/flake.nix" <<'NIX'
{
  outputs = _: { };
}
NIX
cat >"${base}/root/flake.nix" <<NIX
{
  inputs.c.url = "path:${base}/c";
  outputs = _: { };
}
NIX

#######################################
# Print the locked narHash of input c.
# Globals:
#   base
# Arguments:
#   Step label.
#######################################
show_hash() {
  printf '%-22s %s\n' "$1" \
    "$(jq -r '.nodes.c.locked.narHash' "${base}/root/flake.lock")"
}

nix flake lock "path:${base}/root"
show_hash 'after first lock:'

echo x >"${base}/c/x"
nix flake lock "path:${base}/root"
show_hash 'c changed, lock again:'

nix flake update c --flake "path:${base}/root"
show_hash 'after flake update c:'
