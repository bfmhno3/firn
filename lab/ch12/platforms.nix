# 三个平台字段：buildPlatform 是运行构建的机器，hostPlatform 是产物运行的机器，
# targetPlatform 只对编译器之类生成代码的工具有意义。原生、pkgsStatic、
# pkgsCross.aarch64-multiplatform 各取一份；最后列出 lib.systems.elaborate
# "aarch64-linux" 的几个字段。这里只求值，不构建任何东西。
let
  pkgs = import ../../nix/pkgs.nix { };
  inherit (pkgs) lib;
  triple = set: {
    build = set.stdenv.buildPlatform.config;
    host = set.stdenv.hostPlatform.config;
    target = set.stdenv.targetPlatform.config;
  };
  aarch64 = lib.systems.elaborate "aarch64-linux";
in
{
  native = triple pkgs;
  pkgsStatic = triple pkgs.pkgsStatic;
  pkgsCrossAarch64 = triple pkgs.pkgsCross.aarch64-multiplatform;
  elaborateAarch64Linux = {
    inherit (aarch64)
      config
      system
      libc
      linuxArch
      isAarch64
      isLinux
      isStatic
      ;
    cpu = aarch64.parsed.cpu.name;
    kernel = aarch64.parsed.kernel.name;
    abi = aarch64.parsed.abi.name;
    sharedLibrary = aarch64.extensions.sharedLibrary;
    nativeCanExecute = pkgs.stdenv.buildPlatform.canExecute aarch64;
  };
}
