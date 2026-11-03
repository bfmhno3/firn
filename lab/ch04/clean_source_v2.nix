let
  inherit (import (builtins.getEnv "FIRN_ROOT" + "/lib")) hasPrefix;
  isNoise =
    path: type:
    let
      name = baseNameOf path;
    in
    builtins.elem name [
      ".git"
      ".direnv"
      "out"
    ]
    || (type == "symlink" && hasPrefix "result" name);
in
src:
builtins.path {
  path = src;
  name = "source";
  filter = path: type: !(isNoise path type);
}
