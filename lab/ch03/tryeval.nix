# tryEval 只能捕获 throw 和 assert，不能捕获 abort，也不会深度求值。
{
  throwCaught = builtins.tryEval (throw "x");
  assertCaught = builtins.tryEval (
    assert false;
    1
  );
  ok = builtins.tryEval 42;
  # 只求值到 WHNF：内部的毒药不被发现，tryEval 照样成功返回；nix eval 默认格式会把它打印成 «error: inner»，只有 --json 这类要求完整求值的输出才会报错，这里只取 success。
  shallow = (builtins.tryEval { a = throw "inner"; }).success;
  # 要捕获内部错误，必须 deepSeq。
  deep = (builtins.tryEval (builtins.deepSeq { a = throw "inner"; } 1)).success;
}
