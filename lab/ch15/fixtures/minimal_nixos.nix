# 最小的 NixOS 配置：只有能求值所需的几行，不启用任何服务。
let
  nixpkgs = (import ../../../nix/pins.nix).nixpkgs;
in
import "${nixpkgs}/nixos" {
  system = "x86_64-linux";
  configuration = {
    boot.loader.grub.enable = false;
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
    };
    system.stateVersion = "26.05";
  };
}
