# 给 mini 包集加一个 overlay，只改 greeting 的文本：
# 打印 greeting、hello、wordfreq、site 的 out path 有没有变。
# greeting 变，依赖它的 hello 和 site 跟着变，wordfreq 不依赖它所以不变。
let
  system = builtins.currentSystem;
  busybox = import ../../mini/seed.nix { inherit system; };
  mini = import ../../mini { inherit busybox system; };
  hallo = mini.extend (
    final: prev: {
      greeting = prev.callPackage ../../mini/pkgs/greeting.nix { text = "Hallo"; };
    }
  );
  changed = name: mini.${name}.outPath != hallo.${name}.outPath;
in
{
  greeting = changed "greeting";
  hello = changed "hello";
  wordfreq = changed "wordfreq";
  site = changed "site";
}
