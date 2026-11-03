# 源码过滤：把本地目录复制进 store 时丢掉工作区噪音。
let
  strings = import ./strings.nix;

  # builtins.path 的过滤器收到绝对路径和类型，按目录项的名字判断。
  isNoise =
    path:
    let
      name = baseNameOf path;
    in
    builtins.elem name [
      ".git"
      ".direnv"
      "out"
      "result"
    ]
    || strings.hasPrefix "result-" name;

  cleanSource =
    src:
    builtins.path {
      path = src;
      name = "source";
      filter = path: _type: !(isNoise path);
    };
in
{
  inherit cleanSource;
}
