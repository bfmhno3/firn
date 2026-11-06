# 用 nixpkgs 的 lib.evalModules 求值 Firn 的 cairn-settings 模块，
# configText 必须逐字等于 tests/fixtures/cairn.conf（flake 的 cairn-settings 检查同理）。
let
  pkgs = import ../../nix/pkgs.nix { };
  inherit (pkgs) lib;

  evaluated = lib.evalModules {
    modules = [
      ../../modules/cairn-settings.nix
      {
        cairn = {
          repo = "/var/lib/cairn/repo";
          sources = [
            "/srv/data"
            "/etc"
          ];
          excludes = [ "*.tmp" ];
          keep.last = 10;
          keep.weekly = 2;
        };
      }
    ];
  };

  inherit (evaluated.config.cairn) configText;
  fixture = builtins.readFile ../../tests/fixtures/cairn.conf;
in
if configText == fixture then
  {
    lines = lib.splitString "\n" configText;
    matchesFixture = true;
  }
else
  throw "configText differs from tests/fixtures/cairn.conf"
