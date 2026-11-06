# 同样的 packages，一个用 mkShell，一个用 mkShellNoCC。
let
  pkgs = import ../../../nix/pkgs.nix { };
  packages = with pkgs; [
    hello
    jq
  ];
in
{
  withCc = pkgs.mkShell { inherit packages; };
  noCc = pkgs.mkShellNoCC { inherit packages; };
}
