# config 是定点：模块 A 读 config.x，x 由模块 B 定义，加载顺序无关。
# `unused` 的定义会 throw，但没人读它，所以只取 sum 时不会触发。
let
  mini = import ../../modules/mini-modules.nix;
  inherit (mini) evalMini mkOption types;

  moduleA =
    { config, ... }:
    {
      options.sum = mkOption { type = types.int; };
      config.sum = config.x + config.y;
    };

  moduleB = {
    options = {
      x = mkOption { type = types.int; };
      y = mkOption {
        type = types.int;
        default = 10;
      };
      unused = mkOption { type = types.str; };
    };
    config.x = 32;
    config.unused = throw "never forced";
  };

  forward =
    (evalMini {
      modules = [
        moduleA
        moduleB
      ];
    }).config;
  backward =
    (evalMini {
      modules = [
        moduleB
        moduleA
      ];
    }).config;
in
{
  forward = forward.sum;
  backward = backward.sum;
  sameResult = forward.sum == backward.sum;
}
