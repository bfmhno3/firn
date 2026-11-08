# 故意不可复现的包：输出里写进内核每次随机生成的 UUID。
# 只给第 20 章的 `nix build --rebuild` 演示用，不进任何 checks。
{ mkDerivation }:
mkDerivation {
  name = "nondeterministic";
  installPhase = ''
    mkdir -p "$out/share"
    cat /proc/sys/kernel/random/uuid > "$out/share/stamp.txt"
  '';
}
