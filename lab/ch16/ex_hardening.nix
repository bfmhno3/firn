# Exercise: harden cairn.service further. Evaluates a NixOS configuration with
# services.cairn plus an extra module that adds CapabilityBoundingSet and
# SystemCallFilter, and shows the resulting serviceConfig. Re-measure the
# exposure of this unit with `systemd-analyze security` (see the answer).
let
  pins = import ../../nix/pins.nix;
  hardening = {
    systemd.services.cairn.serviceConfig = {
      # 不需要任何 capability：rsync 以 cairn 用户读写自己的文件。
      CapabilityBoundingSet = "";
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
      ];
    };
  };
  os = import "${pins.nixpkgs}/nixos" {
    system = "x86_64-linux";
    configuration = {
      imports = [
        ../../nixos/modules/cairn.nix
        hardening
      ];
      nixpkgs.overlays = [ (import ../../overlays) ];
      services.cairn.enable = true;
      boot.loader.grub.enable = false;
      fileSystems."/" = {
        device = "none";
        fsType = "tmpfs";
      };
      system.stateVersion = "26.05";
    };
  };
in
os.config.systemd.services.cairn.serviceConfig
