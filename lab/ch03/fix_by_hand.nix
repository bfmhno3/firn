# 不动点：fix 把函数的结果当作它自己的参数。
let
  lib = import ../../lib;
  base = self: {
    a = 1;
    b = self.a + 1;
  };
  # 同一件事的手写版，等价于 rec。
  myFix =
    f:
    let
      x = f x;
    in
    x;
  ext = lib.makeExtensible base;
in
{
  fixed = lib.fix base;
  handWritten = myFix base;
  recVersion = rec {
    a = 1;
    b = a + 1;
  };
  # overlay 之后依赖 a 的 b 跟着变。
  extended = lib.fix (lib.extends (_: _: { a = 10; }) base);
  makeExtensibleB = ext.b;
  makeExtensibleExtendB = (ext.extend (_: _: { a = 10; })).b;
  # prev 是扩展前的结果：a 在 prev 里还是 1。
  usesPrev = (ext.extend (_: prev: { a = prev.a + 100; })).b;
  # 原来的对象不受影响。
  originalUntouched = ext.b;
}
