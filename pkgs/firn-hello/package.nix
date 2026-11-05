{
  lib,
  stdenv,
  pkg-config,
  zlib,
  greeting ? "Hello",
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "firn-hello";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../../src/firn-hello;
    fileset = lib.fileset.unions [
      ../../src/firn-hello/firn-hello.c
      ../../src/firn-hello/Makefile
    ];
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ zlib ];

  # pkg-config 的 zlib.pc 把 static 输出的目录排在前面，-lz 会选中 libz.a；
  # 这里用 -lz 配合 cc-wrapper 的 -L，让它动态链接 libz.so。
  makeFlags = [
    "PREFIX=${placeholder "out"}"
    "ZLIB_LIBS=-lz"
  ];

  env.NIX_CFLAGS_COMPILE = "-DFIRN_GREETING=\"${greeting}\"";

  strictDeps = true;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    first="$("$out/bin/${finalAttrs.meta.mainProgram}" nix | head -n 1)"
    test "$first" = '${greeting}, nix, from firn-hello 0.1.0'
    runHook postInstallCheck
  '';

  meta = {
    description = "Greeting program that prints a zlib crc32 of its first line";
    license = [
      lib.licenses.mit
      lib.licenses.asl20
    ];
    mainProgram = "firn-hello";
    platforms = lib.platforms.unix;
  };
})
