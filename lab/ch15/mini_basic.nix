# 用 Firn 的 mini 模块系统求值三个模块：一个声明选项并给默认值，
# 一个只写定义，一个是读 config 的函数。结果是 config 属性集。
let
  mini = import ../../modules/mini-modules.nix;
  inherit (mini) evalMini mkOption types;

  declarations =
    { ... }:
    {
      options = {
        greeting = mkOption {
          type = types.str;
          default = "hello";
        };
        name = mkOption { type = types.str; };
        port = mkOption {
          type = types.int;
          default = 8080;
        };
        message = mkOption { type = types.str; };
      };
    };

  definitions = {
    config.name = "firn";
  };

  derived =
    { config, ... }:
    {
      config.message = "${config.greeting}, ${config.name}";
    };
in
(evalMini {
  modules = [
    declarations
    definitions
    derived
  ];
}).config
