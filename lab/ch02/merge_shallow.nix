# `//` 只合并最外层：{ a.b = 1; } // { a.c = 2; } 丢掉了 b。
let
  lib = import ../../lib;
in
{
  shallow = {
    a.b = 1;
  }
  // {
    a.c = 2;
  };
  deep = lib.recursiveUpdate { a.b = 1; } { a.c = 2; };
  rightWins = lib.recursiveUpdate { a.b = 1; } { a.b = 2; };
}
