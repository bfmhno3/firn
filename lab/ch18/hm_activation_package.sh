#!/usr/bin/env bash
#
# Builds homeConfigurations.demo.activationPackage and takes it apart: the top
# level of the generation, the home-files tree (what gets linked into $HOME),
# the line count of the activate script and the closure size. Store hashes are
# replaced by <hash> so the output is stable.

set -o errexit
set -o nounset
set -o pipefail

readonly ATTR="${FIRN_ROOT}#homeConfigurations.demo.activationPackage"

hide_hash() {
  sed -E 's|/nix/store/[a-z0-9]{32}-|/nix/store/<hash>-|g'
}

main() {
  local pkg
  pkg="$(nix build "${ATTR}" --no-link --print-out-paths)"

  echo "== top level of the generation (symlinks show their target)"
  find "${pkg}/" -mindepth 1 -maxdepth 1 -printf '%f %l\n' | sed 's/ *$//' | sort | hide_hash
  echo
  echo "== home-files: every link that activation puts into \$HOME"
  find "${pkg}/home-files/" -type l -printf '%P -> %l\n' | sort | hide_hash
  echo
  echo "== cairn.conf behind its link"
  cat "${pkg}/home-files/.config/cairn/cairn.conf"
  echo
  echo "== activate"
  echo "lines: $(wc -l <"${pkg}/activate")"
  echo
  echo "== closure"
  nix path-info -S "${pkg}" | awk '{ printf "closure size: %d bytes\n", $2 }'
  echo "closure paths: $(nix path-info -r "${pkg}" | wc -l)"
}

main "$@"
