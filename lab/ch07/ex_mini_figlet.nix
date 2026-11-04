# 练习：给 mini 加一个包 figlet，用 awk 把 greeting 装进字符框。
# 求值时读回构建结果（import from derivation，只在实验里用），所以
# `nix eval --file` 把框打印成字符串列表，每行一项。
let
  system = builtins.currentSystem;
  busybox = import ../../mini/seed.nix { inherit system; };
  mini = import ../../mini { inherit busybox system; };
  figlet = mini.callPackage (
    { mkDerivation, greeting }:
    mkDerivation {
      name = "figlet";
      installPhase = ''
        mkdir -p "$out/share"
        awk '
          {
            bar = "+"
            for (i = 0; i < length($0) + 2; i++) bar = bar "-"
            bar = bar "+"
            print bar
            print "| " $0 " |"
            print bar
          }
        ' ${greeting}/share/greeting.txt > "$out/share/figlet.txt"
      '';
    }
  ) { };
in
builtins.filter (line: line != "") (
  (import ../../lib).splitString "\n" (builtins.readFile "${figlet}/share/figlet.txt")
)
