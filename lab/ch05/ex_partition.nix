# 练习答案：用 foldl' 实现 partition，一次遍历把列表分成满足和不满足条件两组。
let
  partition =
    pred: list:
    builtins.foldl'
      (
        acc: x:
        if pred x then
          {
            right = acc.right ++ [ x ];
            inherit (acc) wrong;
          }
        else
          {
            wrong = acc.wrong ++ [ x ];
            inherit (acc) right;
          }
      )
      {
        right = [ ];
        wrong = [ ];
      }
      list;
  got = partition (x: x > 2) [
    1
    2
    3
    4
    5
  ];
  expected = {
    right = [
      3
      4
      5
    ];
    wrong = [
      1
      2
    ];
  };
in
if got == expected then got else throw "partition mismatch"
