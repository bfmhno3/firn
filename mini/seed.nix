# 种子：锁定版 nixpkgs 里静态链接的 busybox，是 mini 包集唯一从外面借来的东西。
{
  system ? builtins.currentSystem,
}:
(import ../nix/pkgs.nix { inherit system; }).pkgsStatic.busybox
