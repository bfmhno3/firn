# propagation.nix 里 curl 和 python3 的 nativeBuildInputs 各有一个 "(path)"：
# 那是 separate-debug-info.sh，一个 setup hook 文件，由 separateDebugInfo = true
# 加进来。打印这些路径（去掉 nixpkgs 前缀）和两个包的 separateDebugInfo。
let
  pkgs = import ../../nix/pkgs.nix { };
  inherit (builtins) isPath;
  prefix = toString (import ../../nix/pins.nix).nixpkgs;
  strip = p: builtins.substring (builtins.stringLength prefix + 1) (-1) (toString p);
  paths = builtins.filter isPath (pkgs.curl.nativeBuildInputs ++ pkgs.python3.nativeBuildInputs);
in
{
  paths = map strip paths;
  curlSeparateDebugInfo = pkgs.curl.separateDebugInfo or false;
  python3SeparateDebugInfo = pkgs.python3.separateDebugInfo or false;
}
