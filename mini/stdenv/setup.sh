#!/bin/sh
#
# mini stdenv 的通用 builder：由 mkDerivation 交给 busybox sh 执行。
# 环境变量里有 $out、$src、$busybox、$buildInputs，以及可选的
# unpackPhase、patchPhase、buildPhase、installPhase、fixupPhase。
# 依次执行 unpack patch build install fixup，每步前打印 "== phase <name>"。

# shellcheck disable=SC2154 # 这些变量由 Nix 通过环境传入
set -eu

PATH="${busybox}/bin"
# shellcheck disable=SC2086 # 按空格拆开是故意的
for dep in ${buildInputs}; do
  PATH="${dep}/bin:${PATH}"
done
export PATH

# 默认 unpack：目录原样复制，压缩包解开；然后进入源码目录。
default_unpack() {
  mkdir -p "${TMPDIR}/source"
  cd "${TMPDIR}/source"
  if [ -d "${src}" ]; then
    cp -r "${src}/." .
    chmod -R u+w .
  else
    tar xf "${src}"
    # 压缩包只有一个顶层目录时进入它。
    set -- ./*
    if [ "$#" -eq 1 ] && [ -d "$1" ]; then
      cd "$1"
    fi
  fi
}

# 默认 fixup：把 $out/bin 里脚本的 sh 解释器改成 busybox 的绝对路径。
default_fixup() {
  [ -d "${out}/bin" ] || return 0
  for f in "${out}"/bin/*; do
    [ -f "${f}" ] || continue
    sed -i -e "1s|^#!/bin/sh\$|#!${busybox}/bin/sh|" \
      -e "1s|^#!/usr/bin/env sh\$|#!${busybox}/bin/sh|" "${f}"
  done
}

# 运行一个阶段：环境里有 <name>Phase 就写成文件再用 . 载入，
# 没有就用默认实现（有的话）。
run_phase() {
  echo "== phase $1"
  if printenv "$1Phase" >/dev/null 2>&1; then
    printenv "$1Phase" >"${TMPDIR}/phase-$1.sh"
    # shellcheck disable=SC1090 # 阶段文件在运行时才生成
    . "${TMPDIR}/phase-$1.sh"
  elif [ "$1" = unpack ] && [ -n "${src:-}" ]; then
    default_unpack
  elif [ "$1" = fixup ]; then
    default_fixup
  fi
}

mkdir -p "${out}"
for phase in unpack patch build install fixup; do
  run_phase "${phase}"
done
