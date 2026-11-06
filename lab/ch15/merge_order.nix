# 合并顺序：同一个列表选项被五个模块定义。默认顺序号 1000，
# mkBefore 是 mkOrder 500，mkAfter 是 mkOrder 1500；顺序号小的在前。
# 顺序号相同的，后写的模块排在前面（plain-2 在 plain-1 前面）：
# 求值前 lib/modules.nix:274 对收集到的模块 reverseList。
# lines 类型按同样的顺序拼接成多行文本。
let
  pkgs = import ../../nix/pkgs.nix { };
  inherit (pkgs) lib;
  inherit (lib)
    mkAfter
    mkBefore
    mkOption
    mkOrder
    types
    ;

  evaluated = lib.evalModules {
    modules = [
      {
        options = {
          steps = mkOption { type = types.listOf types.str; };
          script = mkOption { type = types.lines; };
        };
      }
      {
        steps = [ "plain-1" ];
        script = "plain-1";
      }
      {
        steps = mkAfter [ "after" ];
        script = mkAfter "after";
      }
      {
        steps = mkBefore [ "before" ];
        script = mkBefore "before";
      }
      {
        steps = mkOrder 750 [ "order-750" ];
        script = mkOrder 750 "order-750";
      }
      {
        steps = [ "plain-2" ];
        script = "plain-2";
      }
    ];
  };
in
{
  inherit (evaluated.config) steps;
  script = lib.splitString "\n" evaluated.config.script;
}
