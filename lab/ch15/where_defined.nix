# 值从哪来：选项对象带着 declarations（谁声明的）和
# definitionsWithLocations（谁定义了什么，只含赢得优先级的那些，所以
# mkDefault 的定义不在里面）。_file 给内联模块一个名字。
let
  pkgs = import ../../nix/pkgs.nix { };
  inherit (pkgs) lib;
  root = "${toString ../..}/";

  evaluated = lib.evalModules {
    modules = [
      ../../modules/cairn-settings.nix
      {
        _file = "defaults.nix";
        cairn.repo = lib.mkDefault "/var/lib/cairn/repo";
      }
      {
        _file = "host.nix";
        cairn.repo = "/srv/backup";
      }
    ];
  };

  inherit (evaluated.options.cairn) repo;
in
{
  value = evaluated.config.cairn.repo;
  declarations = map (lib.removePrefix root) repo.declarations;
  definitions = map (d: {
    inherit (d) file;
    value = d.value;
  }) repo.definitionsWithLocations;
  highestPrio = repo.highestPrio;
}
