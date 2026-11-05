# firn-hello-aarch64 的 nativeBuildInputs 里的 pkg-config 和 buildInputs 里的
# zlib 来自不同的包集：前者的 hostPlatform 是构建机 x86_64（在构建时运行），
# 后者是 aarch64（链接进产物）。package.nix 里没有写 buildPackages；
# callPackage 给的 pkg-config 带 __spliced 属性，make-derivation.nix 在
# nativeBuildInputs 里取 __spliced.buildHost，在 buildInputs 里取
# __spliced.hostTarget 的 dev 输出。最后一段就是对这一点的核对。
let
  pkgs = import ../../nix/pkgs.nix { };
  cross = pkgs.pkgsCross.aarch64-multiplatform;
  inherit (cross) firn-hello;
  describe = dep: {
    inherit (dep) name;
    hostPlatform = dep.stdenv.hostPlatform.config;
    targetPlatform = dep.stdenv.targetPlatform.config;
  };
in
{
  package = firn-hello.name;
  packageHostPlatform = firn-hello.stdenv.hostPlatform.config;
  nativeBuildInputs = map describe firn-hello.nativeBuildInputs;
  buildInputs = map describe firn-hello.buildInputs;
  spliced = {
    pkgConfigSpliceKeys = builtins.attrNames cross.pkg-config.__spliced;
    nativeBuildInputIsBuildHost =
      firn-hello.nativeBuildInputs == [ cross.pkg-config.__spliced.buildHost ];
    zlibBuildInputIsHostTargetDev =
      map (dep: dep.outPath) firn-hello.buildInputs
      == [ (pkgs.lib.getDev cross.zlib.__spliced.hostTarget).outPath ];
  };
}
