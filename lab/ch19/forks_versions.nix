# Which Nix implementations does the pinned nixpkgs carry? The default `nix`,
# the newest upstream release (`nixVersions.latest`) and Lix. Determinate Nix
# is not in nixpkgs: it comes from its own flake (experiments/determinate).
let
  pkgs = import ../../nix/pkgs.nix { };
in
{
  nix = pkgs.nix.version;
  nixVersionsLatest = pkgs.nixVersions.latest.version;
  lix = pkgs.lix.version;
}
