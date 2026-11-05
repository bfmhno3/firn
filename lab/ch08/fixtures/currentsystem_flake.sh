#!/usr/bin/env bash
#
# Shared by pure_eval_fail.sh and pure_eval_impure.sh (sourced, not run).
# Writes a one-file flake whose output reads builtins.currentSystem.

#######################################
# Create the temp flake.
# Globals:
#   LAB_TMP
# Outputs:
#   Writes ${LAB_TMP}/cs/flake.nix.
#######################################
write_flake() {
  mkdir -p "${LAB_TMP}/cs"
  # BAD: flakes must not depend on the machine they are evaluated on.
  cat >"${LAB_TMP}/cs/flake.nix" <<'NIX'
{
  outputs = _: {
    system = builtins.currentSystem;
  };
}
NIX
  echo '== flake.nix'
  cat "${LAB_TMP}/cs/flake.nix"
}
