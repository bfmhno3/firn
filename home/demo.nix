# 一个独立（standalone）的 Home Manager 配置：用户 demo，只装 cairn。
_: {
  home = {
    username = "demo";
    homeDirectory = "/home/demo";
    stateVersion = "26.05";
  };

  programs = {
    cairn = {
      enable = true;
      settings.cairn.sources = [ "/home/demo/Documents" ];
    };
    home-manager.enable = true;
  };
}
