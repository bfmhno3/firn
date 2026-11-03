# import 缓存文件的求值结果；scopedImport 不缓存。
let
  traced = builtins.getEnv "FIRN_ROOT" + "/lab/ch04/fixtures/traced.nix";
  a = builtins.scopedImport { } (/. + traced);
  b = builtins.scopedImport { } (/. + traced);
in
a 1 + b 2
