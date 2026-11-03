# import 的三种用法：文件返回函数、目录取 default.nix、同一文件只求值一次。
# traced.nix 每次求值都会在 stderr 打印一行；三次 import 只应看到一行。
let
  adder = import ./fixtures/adder.nix;
  again = import ./fixtures/traced.nix;
  traced = import ./fixtures/traced.nix;
in
{
  # 文件的值是函数，import 之后就是那个函数。
  fromFile = adder 41;
  # 目录：import ./fixtures/dir 等于 import ./fixtures/dir/default.nix。
  fromDir = import ./fixtures/dir;
  sameAsExplicit = import ./fixtures/dir == import ./fixtures/dir/default.nix;
  # 两个 import 名字不同，但文件相同：trace 只触发一次。
  tracedTwice = again 1 + traced 2;
  tracedAgain = (import ./fixtures/traced.nix) 3;
}
