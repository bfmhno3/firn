# 带一个无关 overlay 的 pkgs：只动 hello，firn-hello 不依赖它。
import ../../../nix/pkgs.nix {
  overlays = [
    (import ../../../overlays)
    (_final: prev: {
      hello = prev.hello.overrideAttrs (_: {
        env.FIRN_TWEAK = "1";
      });
    })
  ];
}
