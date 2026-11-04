# Exercise answer: textStorePath with two references. The references go into
# the fingerprint sorted by path, so the order of the list does not matter
# (both orders must give the real toFile path).
let
  lib = import ../../lib;

  a = builtins.toFile "firn-a" "first\n";
  b = builtins.toFile "firn-b" "second\n";
  content = "uses ${a} and ${b}\n";
  real = builtins.toFile "firn-two-refs" content;
  by =
    references:
    lib.textStorePath {
      name = "firn-two-refs";
      inherit content references;
    };
in
{
  inherit real;
  computedAB = by [
    a
    b
  ];
  computedBA = by [
    b
    a
  ];
  equal =
    by [
      a
      b
    ] == real
    &&
      by [
        b
        a
      ] == real;
}
