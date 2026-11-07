# Exercise: a config file you can edit without a rebuild. Home Manager's
# mkOutOfStoreSymlink makes ~/.config/cairn/cairn.conf point at a path outside
# the store, so edits show up at once. This lab evaluates the demo both ways
# and prints what each puts into the generation, then changes
# programs.cairn.settings and checks whether home-files follows. What the
# out-of-store variant gives up: the file content is not in the store (the
# derivation is one `ln -s`), and the Nix settings no longer reach the file.
let
  flake = builtins.getFlake (toString ../..);
  inherit (flake.inputs) nixpkgs home-manager;
  inherit (nixpkgs) lib;

  mkHome =
    extra:
    home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ flake.overlays.default ];
      };
      modules = [
        flake.homeModules.cairn
        ../../home/demo.nix
        extra
      ];
    };

  # 可写的那一份：source 指向 store 之外的绝对路径，programs.cairn 渲染的 text 让位。
  outOfStore =
    { config, lib, ... }:
    {
      xdg.configFile."cairn/cairn.conf" = {
        source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink "/home/demo/dotfiles/cairn.conf");
        text = lib.mkForce null;
      };
    };
  keepSix.programs.cairn.settings.cairn.keep.last = 6;

  entry = home: home.config.xdg.configFile."cairn/cairn.conf";
  drvText = home: builtins.readFile (entry home).source.drvPath;
  homeFilesDrv = home: home.config.home-files.drvPath;

  stored = mkHome { };
  writable = mkHome outOfStore;
in
{
  stored = {
    sourceName = (entry stored).source.name;
    contentInDrv = lib.hasInfix "keep_last = 5" (drvText stored);
    # 改 settings 会换掉 home-files。
    settingsChangeMovesHomeFiles = homeFilesDrv stored != homeFilesDrv (mkHome keepSix);
  };
  writable = {
    sourceName = (entry writable).source.name;
    linkTargetInDrv = lib.hasInfix "/home/demo/dotfiles/cairn.conf" (drvText writable);
    contentInDrv = lib.hasInfix "keep_last = 5" (drvText writable);
    # 改 settings 不再影响 home-files：配置被静默忽略。
    settingsChangeMovesHomeFiles =
      homeFilesDrv writable != homeFilesDrv (mkHome {
        imports = [
          outOfStore
          keepSix
        ];
      });
  };
}
