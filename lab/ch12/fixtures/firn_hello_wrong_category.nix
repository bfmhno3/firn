# firn-hello 的一份拷贝：pkg-config 从 nativeBuildInputs 挪到了 buildInputs。
# strictDeps = true 时 setup.sh 只把 hostOffset <= -1 的依赖（即
# nativeBuildInputs）的 bin 放进 PATH，所以 Makefile 里的 pkg-config 找不到；
# 这和交叉无关：同样的拷贝做原生构建，strictDeps = true 也以同样的错误失败，
# 只有 strictDeps = false 才通过。交叉构建里 buildInputs 里的 pkg-config
# 还是 aarch64 版本。
# keepZlibLibs 控制是否保留 package.nix 里的 ZLIB_LIBS=-lz。
{
  keepZlibLibs ? true,
}:
let
  pkgs = import ../../../nix/pkgs.nix { };
  inherit (pkgs.pkgsCross.aarch64-multiplatform)
    lib
    stdenv
    zlib
    pkg-config
    ;
in
stdenv.mkDerivation {
  pname = "firn-hello-wrong-category";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../../../src/firn-hello;
    fileset = lib.fileset.unions [
      ../../../src/firn-hello/firn-hello.c
      ../../../src/firn-hello/Makefile
    ];
  };

  # BAD: pkg-config is a build-time tool, it belongs in nativeBuildInputs
  buildInputs = [
    pkg-config
    zlib
  ];

  makeFlags = [
    "PREFIX=${placeholder "out"}"
  ]
  ++ lib.optional keepZlibLibs "ZLIB_LIBS=-lz";

  strictDeps = true;
}
