# lib.fileset：用文件集合而不是 filter 函数选源码。
# fixtures/fileset_demo 里有 main.c、Makefile 和与构建无关的 notes.txt。
#   - toSource + unions 只复制挑中的两个文件，notes.txt 改动不会换 src 的 hash；
#   - 整个目录当 src 则会带上 notes.txt；
#   - lib.fileset.trace 把集合打印到 stderr（trace: 开头的行）。
let
  pkgs = import ../../nix/pkgs.nix { };
  inherit (pkgs) lib;
  root = ./fixtures/fileset_demo;
  picked = lib.fileset.unions [
    (root + "/main.c")
    (root + "/Makefile")
  ];
  src = lib.fileset.toSource {
    inherit root;
    fileset = picked;
  };
  everything = lib.fileset.toSource {
    inherit root;
    fileset = root;
  };
  rel = p: lib.removePrefix "${toString root}/" (toString p);
in
{
  picked_files = map rel (lib.fileset.toList picked);
  picked_in_store = builtins.attrNames (builtins.readDir src);
  everything_in_store = builtins.attrNames (builtins.readDir everything);
  without_notes = map rel (lib.fileset.toList (lib.fileset.difference root (root + "/notes.txt")));
  c_files_only = map rel (lib.fileset.toList (lib.fileset.fileFilter (file: file.hasExt "c") root));
  same_store_path = src.outPath == everything.outPath;
  # trace 返回第二个参数；stderr 里能看到文件集合的树。
  traced = lib.fileset.trace picked "done";
}
