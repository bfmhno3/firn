# 三个带 shellHook 的 shell；combined 用 inputsFrom 把 a、b 合并进来。
let
  pkgs = import ../../../nix/pkgs.nix { };
in
rec {
  a = pkgs.mkShellNoCC { shellHook = ''echo "hook: a"''; };
  b = pkgs.mkShellNoCC { shellHook = ''echo "hook: b"''; };
  combined = pkgs.mkShellNoCC {
    inputsFrom = [
      a
      b
    ];
    shellHook = ''echo "hook: combined (own)"'';
  };
}
