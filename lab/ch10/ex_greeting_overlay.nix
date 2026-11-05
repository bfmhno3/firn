# 练习答案：一个 overlay 让每个用到 firn-hello 的包都默认用 "Hallo"。
# 关键是用 prev.firn-hello.override 替换 firn-hello 本身，这样别的包通过
# callPackage 拿到的 firn-hello 就是改过的。firn-consumer 是一个只依赖 firn-hello
# 的包，它的构建脚本里引用的正是改过的那份；不一致时 assert 让求值失败。
let
  hallo = _final: prev: {
    firn-hello = prev.firn-hello.override { greeting = "Hallo"; };
  };
  consumer = final: _prev: {
    firn-consumer = final.callPackage (
      { runCommand, firn-hello }:
      runCommand "firn-consumer" { } ''
        ${firn-hello}/bin/firn-hello consumer > $out
      ''
    ) { };
  };
  pkgs = import ../../nix/pkgs.nix {
    overlays = [
      (import ../../overlays)
      hallo
      consumer
    ];
  };
  plain = import ../../nix/pkgs.nix { };
  greeting = drv: drv.drvAttrs.NIX_CFLAGS_COMPILE;
  hallo' = plain.firn-hello.override { greeting = "Hallo"; };
  strip = builtins.unsafeDiscardStringContext;
  usesOverlaid = pkgs.lib.hasInfix (strip "${pkgs.firn-hello}") (
    strip pkgs.firn-consumer.drvAttrs.buildCommand
  );
in
assert pkgs.firn-hello.drvPath == hallo'.drvPath;
assert usesOverlaid;
{
  firn_hello = greeting pkgs.firn-hello;
  plain_firn_hello = greeting plain.firn-hello;
  consumer_uses_overlaid_firn_hello = usesOverlaid;
  same_drv_as_override = pkgs.firn-hello.drvPath == hallo'.drvPath;
}
