# 两个模块给 cairn.repo 写了不同的字符串：str 的合并要求相等。
# 错误文本列出每个定义和它的文件，对照 mini 的单行错误。
let
  pkgs = import ../../nix/pkgs.nix { };
  evaluated = pkgs.lib.evalModules {
    modules = [
      ../../modules/cairn-settings.nix
      {
        _file = "team-a.nix";
        cairn.repo = "/srv/backup-a";
      }
      {
        _file = "team-b.nix";
        cairn.repo = "/srv/backup-b";
      }
    ];
  };
in
evaluated.config.cairn.configText
