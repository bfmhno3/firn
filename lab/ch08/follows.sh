#!/usr/bin/env bash
#
# `follows` merges duplicate inputs. Offline: four temp flakes with `path:`
# inputs. Flakes a and b both depend on a leaf flake c, and the root flake
# depends on a, b and c. Without `follows` the lock file holds one node per
# dependency edge of c; with `follows` it holds one.

set -o errexit
set -o nounset
set -o pipefail

readonly base="${LAB_TMP}/follows"

#######################################
# Write the leaf flake c and the middle flakes a and b.
# Globals:
#   base
#######################################
write_leaves() {
  mkdir -p "${base}/c" "${base}/a" "${base}/b"
  cat >"${base}/c/flake.nix" <<'NIX'
{
  outputs = _: { };
}
NIX
  local name
  for name in a b; do
    cat >"${base}/${name}/flake.nix" <<NIX
{
  inputs.c.url = "path:${base}/c";
  outputs = _: { };
}
NIX
  done
}

#######################################
# Write the root flake and lock it.
# Globals:
#   base
# Arguments:
#   Directory name of the root flake, then the extra lines for the inputs.
#######################################
write_root() {
  local dir="$1"
  local extra="$2"
  mkdir -p "${base}/${dir}"
  cat >"${base}/${dir}/flake.nix" <<NIX
{
  inputs.a.url = "path:${base}/a";
  inputs.b.url = "path:${base}/b";
  inputs.c.url = "path:${base}/c";
${extra}
  outputs = _: { };
}
NIX
  nix flake lock "path:${base}/${dir}"
  echo "== ${dir}/flake.nix inputs"
  grep -E '^  inputs' "${base}/${dir}/flake.nix" | sed "s|${base}|\$BASE|"
  echo "nodes:  $(jq -r '.nodes | keys | join(" ")' "${base}/${dir}/flake.lock")"
  echo "count:  $(jq '.nodes | length' "${base}/${dir}/flake.lock")"
  echo "root inputs:     $(jq -c '.nodes.root.inputs' "${base}/${dir}/flake.lock")"
  echo "a's inputs:      $(jq -c '.nodes.a.inputs' "${base}/${dir}/flake.lock")"
  echo
}

write_leaves
write_root plain ''
write_root followed '  inputs.a.inputs.c.follows = "c";
  inputs.b.inputs.c.follows = "c";'
