# 故意出错：overlay 里改一个包，却从 final 取旧值。
# final 是包括这个 overlay 自己在内的最终结果，firn-hello 的定义里要 final.firn-hello，
# 即它自己，于是 infinite recursion。改成 prev.firn-hello 就对了（见 overlay_order.nix）。
let
  # BAD: 应该用 prev.firn-hello
  bad = final: _prev: {
    firn-hello = final.firn-hello.override { greeting = "Hallo"; };
  };
  pkgs = import ../../nix/pkgs.nix {
    overlays = [
      (import ../../overlays)
      bad
    ];
  };
in
pkgs.firn-hello.name
