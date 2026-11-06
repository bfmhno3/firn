#!/usr/bin/env bash
#
# Shared by untracked_invisible_fail.sh and untracked_fixed.sh (sourced, not
# run). Clones the repository into LAB_TMP and adds an untracked file extra.nix
# that a new flake output `extra` imports.

#######################################
# Clone the repo and wire an untracked file into its flake.nix.
# Globals:
#   FIRN_ROOT, LAB_TMP
# Outputs:
#   Writes ${LAB_TMP}/clone.
#######################################
setup_clone() {
  git clone --quiet "${FIRN_ROOT}" "${LAB_TMP}/clone"
  cd "${LAB_TMP}/clone" || return 1
  echo '"extra output from an untracked file"' >extra.nix
  # flake.nix is tracked, so this edit is visible; extra.nix is not.
  # The anchor is the overlays.default output, which stays in flake.nix from chapter 10 on.
  sed -i 's|^      overlays.default = import ./overlays;|      extra = import ./extra.nix;\n&|' flake.nix
  if ! grep -q 'extra = import ./extra.nix;' flake.nix; then
    echo 'untracked_setup: flake.nix anchor not found' >&2
    return 1
  fi
  echo '== git status --short'
  git status --short
}
