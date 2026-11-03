# seq 只求值到弱头范式（WHNF）：属性集本身是值，里面的 thunk 不动。
let
  s = {
    a = throw "x";
  };
in
{
  seqOnSet = builtins.seq s "set is already in WHNF";
  seqOnList = builtins.seq [ (throw "y") ] "list too";
  seqOnLambda = builtins.seq (x: throw "z") "lambda too";
  # deepSeq 会失败，见 deepseq_fail.nix；这里只深度求值没有毒药的值。
  deepOk = builtins.deepSeq {
    a = 1;
    b = [ 2 ];
  } "fully forced";
  # builtins.length 只看列表的骨架，不看元素。
  length = builtins.length [ (throw "w") ];
}
