# 一个拒绝被构建的派生：buildPhase 直接失败。`nix build` 因此失败，但
# `nix develop -f` 只构建它的输入，从不运行它，所以照样能进入环境。
# 这就是 mkShell 的做法：派生只是用来承载 buildInputs 和 shellHook 的壳。
let
  pkgs = import ../../../nix/pkgs.nix { };
in
pkgs.stdenv.mkDerivation {
  name = "refuses-to-build";
  phases = [ "buildPhase" ];
  nativeBuildInputs = [ pkgs.hello ];
  buildPhase = ''
    echo "this derivation is not meant to be built" >&2
    false
  '';
  shellHook = ''
    echo "shellHook ran, hello is $(command -v hello)"
  '';
}
