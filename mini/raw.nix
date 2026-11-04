# 最原始的 derivation：一个名字加一段 sh 脚本，只用 busybox，没有 stdenv。
{ busybox, system }:
{ name, script }:
derivation {
  inherit name system;
  builder = "${busybox}/bin/sh";
  args = [
    "-c"
    script
  ];
  PATH = "${busybox}/bin";
}
