# firn-hello 不加 ZLIB_LIBS=-lz 时的样子：Makefile 用 pkg-config --libs zlib，
# zlib.pc 里 static 输出的目录排在前面，链接器先找到 libz.a，静态链接。
let
  pkgs = import ../../../nix/pkgs.nix { };
in
pkgs.firn-hello.overrideAttrs (old: {
  pname = "firn-hello-pcstatic";
  makeFlags = builtins.filter (f: !(pkgs.lib.hasPrefix "ZLIB_LIBS=" f)) old.makeFlags;
})
