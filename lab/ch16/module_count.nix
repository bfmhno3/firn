# How many modules does every NixOS evaluation import before the host's own?
# module-list.nix of the pinned nixpkgs is that list; the second number is
# the module graph of nixosConfigurations.lab (the list, plus the host
# modules and the ones `nixosSystem` adds).
let
  pkgs = import ../../nix/pkgs.nix { };
  lab = (builtins.getFlake (toString ../..)).nixosConfigurations.lab;
in
{
  moduleList = builtins.length (import "${pkgs.path}/nixos/modules/module-list.nix");
  labGraph = builtins.length lab.graph;
}
