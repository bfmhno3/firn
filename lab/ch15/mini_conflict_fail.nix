# 两个模块给同一个标量选项写了不同的值，优先级相同：冲突。
# deepSeq 让错误真的抛出来（否则 nix eval 只打印 «error: …» 并退出 0）。
# 预期错误：firn: option 'port' has conflicting definitions
let
  mini = import ../../modules/mini-modules.nix;
  inherit (mini) evalMini mkOption types;
  result =
    (evalMini {
      modules = [
        { options.port = mkOption { type = types.int; }; }
        { config.port = 8080; }
        { config.port = 9090; }
      ];
    }).config;
in
builtins.deepSeq result result
