# tryEval 只能捕获 throw 和 assert，不能捕获 abort，也不会深度求值。
{
  throwCaught = builtins.tryEval (throw "x");
  assertCaught = builtins.tryEval (
    assert false;
    1
  );
  ok = builtins.tryEval 42;
  # 只求值到 WHNF：内部的毒药不被发现，成功返回，打印时才炸，所以这里不打印它。
  shallow = (builtins.tryEval { a = throw "inner"; }).success;
  # 要捕获内部错误，必须 deepSeq。
  deep = (builtins.tryEval (builtins.deepSeq { a = throw "inner"; } 1)).success;
}
