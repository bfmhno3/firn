# 不经过 flake 导入锁定版本的 nixpkgs。
{
  system ? builtins.currentSystem,
  overlays ? [ (import ../overlays) ],
}:
import (import ./pins.nix).nixpkgs {
  inherit system overlays;
  config = { };
}
