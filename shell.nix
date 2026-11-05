# 不用 flake 的开发环境：`nix-shell`。
let
  pkgs = import ./nix/pkgs.nix { };
in
pkgs.mkShellNoCC {
  packages = with pkgs; [
    nixfmt
    statix
    deadnix
    jq
  ];
}
