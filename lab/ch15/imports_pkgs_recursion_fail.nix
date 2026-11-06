# BAD: imports 里用了 _module.args 的值。imports 在 config 之前展开，
# 而 _module.args 是 config 的一部分，于是 imports 依赖 config、
# config 又依赖 imports：infinite recursion。改用 specialArgs 就好（见 specialargs.nix）。
let
  pkgs = import ../../nix/pkgs.nix { };
  inherit (pkgs) lib;

  evaluated = lib.evalModules {
    modules = [
      (
        { extra, ... }:
        {
          imports = if extra then [ { options.x = lib.mkOption { default = 1; }; } ] else [ ]; # BAD
        }
      )
      { _module.args.extra = true; }
    ];
  };
in
evaluated.config.x
