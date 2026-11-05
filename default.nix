# 不用 flake 的入口：`nix-build -A mini.hello`。
# 之后的章节会继续往这里加包。
{
  system ? builtins.currentSystem,
}:
let
  pkgs = import ./nix/pkgs.nix { inherit system; };
in
{
  mini = import ./mini {
    busybox = pkgs.pkgsStatic.busybox;
    inherit system;
  };
}
