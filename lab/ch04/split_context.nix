# Firn 的 splitString 和 nixpkgs 的 splitString：谁保住了字符串上下文？
let
  firn = import (builtins.getEnv "FIRN_ROOT" + "/lib");
  pkgs = import (builtins.getEnv "FIRN_ROOT" + "/nix/pkgs.nix") { };
  s = "${pkgs.hello}/bin/hello";
  first = parts: builtins.head parts;
in
{
  firn = builtins.hasContext (first (firn.splitString "/bin" s));
  nixpkgs = builtins.hasContext (first (pkgs.lib.splitString "/bin" s));
  trick = builtins.hasContext (builtins.substring 0 0 s + "plain");
}
