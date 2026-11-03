# runTests 只返回失败的用例，每项是 { name; expected; result; }。
let
  lib = import ../../lib;
in
lib.runTests (import ./fixtures/broken_tests.nix)
