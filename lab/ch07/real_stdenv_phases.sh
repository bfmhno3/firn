#!/usr/bin/env bash
#
# Runs the phases of the real stdenv by hand for the pinned hello, in LAB_TMP.
# `nix develop --command` execs the command, so the phase functions of the
# dev environment are gone in it; part 1 shows that. Part 2 sources the
# environment from `nix print-dev-env` (what interactive `nix develop` does)
# and runs unpackPhase, configurePhase, buildPhase. Prints the tail of the
# output and $phases (the dev environment sets it to buildPhase; a normal
# build leaves it unset and setup.sh uses its default list).

set -o errexit
set -o nounset
set -o pipefail

readonly pkgs_nix="${FIRN_ROOT}/nix/pkgs.nix"

cd "${LAB_TMP}"

echo "== nix develop --command: are the phase functions there?"
# shellcheck disable=SC2016 # the script is for the inner bash
nix develop -f "${pkgs_nix}" hello --command bash -c '
  type unpackPhase 2>&1 | head -n 1
  echo "phases: ${phases:-default}"
' 2>/dev/null

echo
echo "== phases from print-dev-env (tail, lines cut to 100 columns)"
nix print-dev-env -f "${pkgs_nix}" hello >env.sh 2>/dev/null
# shellcheck disable=SC2016 # the script is for the inner bash
bash -c '
  source ./env.sh
  unpackPhase
  cd hello-*
  configurePhase
  buildPhase
  echo "phases: ${phases:-default}"
' 2>&1 | tail -n 8 | cut -c1-100
