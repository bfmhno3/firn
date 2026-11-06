#!/usr/bin/env bash
#
# The python template end to end, inside LAB_TMP, created with `nix flake new
# -t` this time (flake init writes into the current directory, flake new into
# a fresh one). Then `git init && git add -A`, pin nixpkgs to firn's lock (see
# template_c.sh), and `nix run`, which builds the hatchling package with
# buildPythonApplication and runs the `hello` entry point from pyproject.toml.
# Finally the dev shell: the lab prints the versions of python3, ruff and
# pytest on its PATH. The versions are volatile.

set -o errexit
set -o nounset
set -o pipefail

readonly LOCK="${FIRN_ROOT}/flake.lock"

main() {
  local rev nar_hash
  rev="$(jq -r '.nodes.nixpkgs.locked.rev' "${LOCK}")"
  nar_hash="$(jq -r '.nodes.nixpkgs.locked.narHash' "${LOCK}")"

  echo "== nix flake new -t firn#python"
  cd "${LAB_TMP}"
  nix flake new hello-py -t "${FIRN_ROOT}#python" 2>&1 \
    | grep -v "^warning" | sed "s|${LAB_TMP}|\$LAB_TMP|"
  cd hello-py
  git init -q
  git add -A
  find . -path ./.git -prune -o -type f -print | LC_ALL=C sort

  echo
  echo "== nix run"
  nix flake lock --override-input nixpkgs \
    "github:NixOS/nixpkgs/${rev}?narHash=${nar_hash}" 2>/dev/null
  git add -A
  nix run 2>/dev/null

  echo
  echo "== nix develop"
  nix develop --command bash -c \
    'python3 --version; ruff --version; pytest --version' 2>/dev/null \
    | sed 's/^/volatile: /'
}

main "$@"
