#!/usr/bin/env bash
#
# Answer to the exercise "add a Rust template": a third template, added in
# a temporary copy so firn's own `templates` stays at c and python. The copy
# is a tiny flake in LAB_TMP whose templates.rust points at
# fixtures/rust-template (flake.nix with rustPlatform.buildRustPackage and a
# mkShell with cargo, clippy and rustfmt, plus Cargo.toml, a Cargo.lock with
# no dependencies, src/main.rs and .envrc). The lab inits a project from it,
# pins nixpkgs to firn's lock, builds, runs the binary and checks the dev
# shell. Store paths and tool versions are volatile.

set -o errexit
set -o nounset
set -o pipefail

readonly FIXTURE="${FIRN_ROOT}/lab/ch13/fixtures/rust-template"

main() {
  local rev nar_hash
  rev="$(jq -r '.nodes.nixpkgs.locked.rev' "${FIRN_ROOT}/flake.lock")"
  nar_hash="$(jq -r '.nodes.nixpkgs.locked.narHash' "${FIRN_ROOT}/flake.lock")"

  echo "== a temporary flake with a third template"
  mkdir -p "${LAB_TMP}/tpl/templates"
  cp -r "${FIXTURE}" "${LAB_TMP}/tpl/templates/rust"
  chmod -R u+w "${LAB_TMP}/tpl"
  cat >"${LAB_TMP}/tpl/flake.nix" <<'NIX'
{
  outputs =
    { ... }:
    {
      templates.rust = {
        path = ./templates/rust;
        description = "Rust project: buildRustPackage and a cargo dev shell";
      };
    };
}
NIX
  nix eval --json "path:${LAB_TMP}/tpl#templates.rust.description"

  echo
  echo "== nix flake init -t tpl#rust"
  mkdir "${LAB_TMP}/hello-rs"
  cd "${LAB_TMP}/hello-rs"
  nix flake init -t "path:${LAB_TMP}/tpl#rust" >/dev/null 2>&1
  git init -q
  git add -A
  find . -path ./.git -prune -o -type f -print | LC_ALL=C sort

  echo
  echo "== nix build"
  nix flake lock --override-input nixpkgs \
    "github:NixOS/nixpkgs/${rev}?narHash=${nar_hash}" 2>/dev/null
  git add -A
  local out
  out="$(nix build --no-link --print-out-paths 2>/dev/null)"
  printf 'volatile: %s\n' "${out}"
  "${out}/bin/hello-rs"

  echo
  echo "== nix develop"
  nix develop --command bash -c 'cargo --version; rustfmt --version' \
    2>/dev/null \
    | sed 's/^/volatile: /'
}

main "$@"
