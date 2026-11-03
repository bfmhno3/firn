# genericClosure：从起点出发，沿 operator 给出的邻居做闭包，按 key 去重。
# 这里用一张玩具依赖图；图里有环（c -> a），闭包照样终止。
let
  graph = {
    app = [
      "lib"
      "cli"
    ];
    lib = [
      "libc"
      "zlib"
    ];
    cli = [
      "lib"
      "libc"
    ];
    zlib = [ "libc" ];
    libc = [ ];
    cycle-a = [ "cycle-b" ];
    cycle-b = [ "cycle-a" ];
  };
  closure =
    root:
    builtins.genericClosure {
      startSet = [ { key = root; } ];
      operator = item: map (key: { inherit key; }) graph.${item.key};
    };
in
{
  app = map (x: x.key) (closure "app");
  zlib = map (x: x.key) (closure "zlib");
  cycle = map (x: x.key) (closure "cycle-a");
}
