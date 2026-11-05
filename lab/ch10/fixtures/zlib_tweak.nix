# 带一个 zlib overlay 的 pkgs：zlib 的 drv 换了，依赖它的包都跟着换。
import ../../../nix/pkgs.nix {
  overlays = [
    (import ../../../overlays)
    (_final: prev: {
      zlib = prev.zlib.overrideAttrs (_: {
        env.FIRN_TWEAK = "1";
      });
    })
  ];
}
