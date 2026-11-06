# 实验用的 NixOS 主机：x86_64-linux，只用来求值、构建和在虚拟机里启动，
# 不会装到真机上。
{ pkgs, ... }:
{
  services.cairn = {
    enable = true;
    settings.cairn.sources = [ "/srv/data" ];
  };

  # 求值需要一个引导器和一个根文件系统；虚拟机变体会替换掉它们。
  boot.loader.grub = {
    enable = true;
    device = "nodev";
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  users.users.firn = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # 只给虚拟机里登录用；真机上永远不要把明文口令写进配置。
    initialPassword = "firn";
  };

  environment.systemPackages = [ pkgs.cairn ];

  virtualisation.vmVariant.virtualisation.memorySize = 2048;

  # 记录首次安装时的 NixOS 版本，决定有状态数据的默认布局；装好以后不要改。
  system.stateVersion = "26.05";
}
