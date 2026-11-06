# specialArgs 和 _module.args 都能把值传给模块函数，区别在于 imports：
# imports 要在求值 config 之前展开，只能用 specialArgs。
# 这里 specialArgs.flavor 选择了要导入的模块，_module.args.suffix 只在函数体里用。
let
  pkgs = import ../../nix/pkgs.nix { };
  inherit (pkgs) lib;

  evaluated = lib.evalModules {
    specialArgs.flavor = "sweet";
    modules = [
      (
        { flavor, ... }:
        {
          imports = [ (if flavor == "sweet" then sweet else salty) ];
        }
      )
      (
        { suffix, flavor, ... }:
        {
          options.out = lib.mkOption { type = lib.types.str; };
          config = {
            _module.args.suffix = "!";
            out = "${flavor}${suffix}";
          };
        }
      )
    ];
  };

  sweet = {
    options.dessert = lib.mkOption {
      type = lib.types.str;
      default = "cake";
    };
  };
  salty = {
    options.snack = lib.mkOption {
      type = lib.types.str;
      default = "chips";
    };
  };
in
{
  inherit (evaluated.config) out;
  declared = builtins.attrNames (builtins.removeAttrs evaluated.options [ "_module" ]);
}
