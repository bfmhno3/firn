# 两个 overlay 按两种顺序叠加。`prev` 是它前面所有 overlay 的结果，
# `final` 是全部叠完的结果，所以：
#   - 两个都改 prev.firn-hello 的 overlay，后面的赢（顺序决定结果）；
#   - observe 里取自 prev 的 firn-hello-prev 只看到排在它前面的 overlay，
#     取自 final 的 firn-hello-final 总是看到最后的结果；
# greeting 取自 NIX_CFLAGS_COMPILE，不构建任何东西。
let
  pkgs = import ../../nix/pkgs.nix { };
  hallo = _final: prev: {
    firn-hello = prev.firn-hello.override { greeting = "Hallo"; };
  };
  bonjour = _final: prev: {
    firn-hello = prev.firn-hello.override { greeting = "Bonjour"; };
  };
  observe = final: prev: {
    firn-hello-prev = prev.firn-hello;
    firn-hello-final = final.firn-hello;
  };
  firn = import ../../overlays;
  greetingOf = drv: drv.drvAttrs.NIX_CFLAGS_COMPILE;
  stack =
    overlays:
    let
      p = pkgs.appendOverlays overlays;
    in
    {
      firn-hello = greetingOf p.firn-hello;
      prev_seen_by_observe = greetingOf p.firn-hello-prev;
      final_seen_by_observe = greetingOf p.firn-hello-final;
    };
  composed =
    let
      p = import ../../nix/pkgs.nix {
        overlays = [
          firn
          (pkgs.lib.composeManyExtensions [
            hallo
            bonjour
          ])
        ];
      };
    in
    greetingOf p.firn-hello;
  separate =
    let
      p = import ../../nix/pkgs.nix {
        overlays = [
          firn
          hallo
          bonjour
        ];
      };
    in
    greetingOf p.firn-hello;
in
{
  # nix/pkgs.nix 默认已带 Firn 的 overlay；下面是它之后再叠的。
  hallo_bonjour_observe = stack [
    hallo
    bonjour
    observe
  ];
  bonjour_hallo_observe = stack [
    bonjour
    hallo
    observe
  ];
  observe_hallo_bonjour = stack [
    observe
    hallo
    bonjour
  ];
  composeManyExtensions_equals_list = composed == separate;
}
