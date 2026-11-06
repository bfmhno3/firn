# BAD: config 的形状（有没有 out 这个属性）取决于 cfg.enable，
# 而 cfg.enable 要先收集所有模块 config 里的定义，其中就有这个模块自己。
let
  pkgs = import ../../../nix/pkgs.nix { };
  inherit (pkgs) lib;
  evaluated = lib.evalModules {
    modules = [
      (
        { config, ... }:
        let
          cfg = config.demo;
        in
        {
          options.demo.enable = lib.mkEnableOption "the demo";
          options.demo.out = lib.mkOption {
            type = lib.types.str;
            default = "off";
          };
          config = if cfg.enable then { demo.out = "on"; } else { }; # BAD
        }
      )
      { demo.enable = true; }
    ];
  };
in
evaluated.config.demo.out
