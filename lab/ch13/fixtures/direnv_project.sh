#!/usr/bin/env bash
#
# Shared setup of direnv_cache.sh and devshell_gc_root.sh: a project in
# LAB_TMP created from the c template, with direnv confined to LAB_TMP.
# direnv reads its configuration from XDG_CONFIG_HOME, keeps the "allowed"
# list in XDG_DATA_HOME and its cache in XDG_CACHE_HOME; all three point into
# LAB_TMP, so `direnv allow` here never touches the real allow list. Sourced,
# not executed.

# shellcheck source=lab/ch13/fixtures/pin_nixpkgs.sh
source "${FIRN_ROOT}/lab/ch13/fixtures/pin_nixpkgs.sh"

#######################################
# Create the project and the direnv directories.
# Globals:
#   FIRN_ROOT, LAB_TMP, FIRN_NIX_DIRENV (read);
#   XDG_CONFIG_HOME, XDG_DATA_HOME, XDG_CACHE_HOME (exported)
# Arguments:
#   "with" to install a direnvrc that sources nix-direnv, anything else for
#   an empty direnv configuration.
# Outputs:
#   Nothing; the project is ${LAB_TMP}/proj.
#######################################
direnv_project::setup() {
  local mode="$1"
  export XDG_CONFIG_HOME="${LAB_TMP}/xdg/config"
  export XDG_DATA_HOME="${LAB_TMP}/xdg/data"
  export XDG_CACHE_HOME="${LAB_TMP}/xdg/cache"
  mkdir -p "${XDG_CONFIG_HOME}/direnv" "${XDG_DATA_HOME}" "${XDG_CACHE_HOME}"
  if [[ "${mode}" == with ]]; then
    printf 'source "%s"\n' "${FIRN_NIX_DIRENV}" \
      >"${XDG_CONFIG_HOME}/direnv/direnvrc"
  fi

  mkdir -p "${LAB_TMP}/proj"
  cd "${LAB_TMP}/proj" || return 1
  nix flake init -t "${FIRN_ROOT}#c" >/dev/null 2>&1
  git init -q
  git add -A
  pin_nixpkgs::lock
  git add -A
  printf 'use flake\n' >.envrc
  # 外层 shell 如果也在用 direnv，这些变量会让 direnv 以为已经加载过。
  unset "${!DIRENV_@}"
  direnv allow . 2>/dev/null
}
