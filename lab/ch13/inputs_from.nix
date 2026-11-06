# inputsFrom 只取别的派生的各类 inputs 列表，不取派生本身：
# firn-hello 的 buildInputs、nativeBuildInputs 进了 shell，firn-hello 没有进。
# packages 追加在 nativeBuildInputs 的最前面。只求值，不构建。
let
  pkgs = import ../../nix/pkgs.nix { };
  inherit (pkgs) lib;
  names = map (drv: drv.name);
  shell = pkgs.mkShell {
    inputsFrom = [ pkgs.firn-hello ];
    packages = [ pkgs.gdb ];
  };
in
{
  firnHello = {
    buildInputs = names pkgs.firn-hello.buildInputs;
    nativeBuildInputs = names pkgs.firn-hello.nativeBuildInputs;
  };
  shell = {
    buildInputs = names shell.buildInputs;
    nativeBuildInputs = names shell.nativeBuildInputs;
    propagatedBuildInputs = names shell.propagatedBuildInputs;
  };
  firnHelloItselfInShell = lib.any (drv: drv == pkgs.firn-hello) (
    shell.buildInputs ++ shell.nativeBuildInputs
  );
  # firn-hello 的 env.NIX_CFLAGS_COMPILE 不属于 inputs，不会带进 shell。
  shellHasGreetingFlag = shell ? env && shell.env ? NIX_CFLAGS_COMPILE;
}
