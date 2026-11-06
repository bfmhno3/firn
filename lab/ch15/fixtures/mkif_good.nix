# mkIf 把条件留在每个定义里：模块的 config 先是 { _type = "if"; … }，
# 属性名不依赖 cfg.enable，条件到合并这个选项时才求值。
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
          config = lib.mkIf cfg.enable { demo.out = "on"; };
        }
      )
      { demo.enable = true; }
    ];
  };
in
evaluated.config.demo.out
