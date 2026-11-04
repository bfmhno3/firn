# callPackage 手工拆开：functionArgs 说明函数要什么，intersectAttrs 从包集里
# 挑出恰好需要的那几项。site.nix 要 mkDerivation、hello、wordfreq、cairn-src，
# 包集里另有 busybox、greeting 等别的项，callPackage 一个也不多给。
let
  system = builtins.currentSystem;
  busybox = import ../../mini/seed.nix { inherit system; };
  mini = import ../../mini { inherit busybox system; };
  f = import ../../mini/pkgs/site.nix;
  wanted = builtins.functionArgs f;
  supplied = builtins.intersectAttrs wanted mini;
in
{
  functionArgs = wanted;
  setAttrNames = builtins.attrNames mini;
  suppliedNames = builtins.attrNames supplied;
  sameOutPath = (f supplied).outPath == mini.site.outPath;
}
