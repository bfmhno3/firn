# 选项声明为 int，定义里却给了字符串。deepSeq 让错误抛出来。
# 预期错误：firn: option 'port' has type int but got "8080"
let
  mini = import ../../modules/mini-modules.nix;
  inherit (mini) evalMini mkOption types;
  result =
    (evalMini {
      modules = [
        { options.port = mkOption { type = types.int; }; }
        { config.port = "8080"; }
      ];
    }).config;
in
builtins.deepSeq result result
