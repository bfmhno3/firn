# keep.last 的类型是 ints.positive，0 不合格。看错误文本：
# 它说出选项路径、类型描述、值和定义所在的文件。
let
  pkgs = import ../../nix/pkgs.nix { };
  evaluated = pkgs.lib.evalModules {
    modules = [
      ../../modules/cairn-settings.nix
      {
        _file = "lab/ch15/real_type_fail.nix";
        cairn = {
          repo = "/var/lib/cairn/repo";
          keep.last = 0;
        };
      }
    ];
  };
in
evaluated.config.cairn.configText
