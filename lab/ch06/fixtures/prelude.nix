# ch06 实验共用：种子 busybox 和 mini/raw.nix 的 raw 函数。
let
  system = builtins.currentSystem;
  busybox = import ../../../mini/seed.nix { inherit system; };
in
{
  inherit busybox system;
  raw = import ../../../mini/raw.nix { inherit busybox system; };
}
