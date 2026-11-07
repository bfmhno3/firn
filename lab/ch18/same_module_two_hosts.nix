# One module, two hosts: modules/cairn-settings.nix sits inside services.cairn
# (NixOS) and programs.cairn (Home Manager). Give both the same settings and
# compare the configText each evaluation renders. Throws on a mismatch, so a
# non-zero exit means the two hosts disagree.
let
  flake = builtins.getFlake (toString ../..);
  inherit (flake.inputs) nixpkgs home-manager;
  system = "x86_64-linux";

  settings.cairn = {
    repo = "/srv/backup/repo";
    sources = [
      "/srv/data"
      "/etc"
    ];
    excludes = [ "*.tmp" ];
    keep.last = 10;
    keep.weekly = 2;
  };

  nixos = nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      flake.nixosModules.default
      {
        services.cairn = {
          enable = true;
          inherit settings;
        };
      }
    ];
  };

  home = home-manager.lib.homeManagerConfiguration {
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ flake.overlays.default ];
    };
    modules = [
      flake.homeModules.cairn
      {
        home = {
          username = "demo";
          homeDirectory = "/home/demo";
          stateVersion = "26.05";
        };
        programs.cairn = {
          enable = true;
          inherit settings;
        };
      }
    ];
  };

  nixosText = nixos.config.services.cairn.settings.cairn.configText;
  homeText = home.config.programs.cairn.settings.cairn.configText;
  fixture = builtins.readFile ../../tests/fixtures/cairn.conf;
in
if nixosText != homeText then
  throw "configText differs between NixOS and Home Manager:\n${nixosText}\n---\n${homeText}"
else
  {
    equal = true;
    # tests/fixtures/cairn.conf is the file checks.cairn-settings compares with:
    # same settings except the repo path.
    sameAsFixtureExceptRepo =
      builtins.tail (nixpkgs.lib.splitString "\n" nixosText)
      == builtins.tail (nixpkgs.lib.splitString "\n" fixture);
    configText = nixosText;
  }
