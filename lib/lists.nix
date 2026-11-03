# 列表工具，只依赖 builtins。
let
  # range 2 5 == [ 2 3 4 5 ]；first > last 时是空列表。
  range =
    first: last: if first > last then [ ] else builtins.genList (n: first + n) (last - first + 1);

  # 保留首次出现的元素，用 == 比较，O(n^2)。
  unique = builtins.foldl' (acc: x: if builtins.elem x acc then acc else acc ++ [ x ]) [ ];

  # 递归拍平嵌套列表；非列表的参数当作单元素列表。
  flatten = x: if builtins.isList x then builtins.concatMap flatten x else [ x ];

  # foldl' 是严格的，不会堆出一长串 thunk。
  sum = builtins.foldl' builtins.add 0;

  # 第一个满足 pred 的元素，没有就返回 default；找到后不再看后面的元素。
  findFirst =
    pred: default: list:
    if list == [ ] then
      default
    else if pred (builtins.head list) then
      builtins.head list
    else
      findFirst pred default (builtins.tail list);

  # 从 0 开始的下标：imap0 f [ a b ] == [ (f 0 a) (f 1 b) ]。
  imap0 = f: list: builtins.genList (i: f i (builtins.elemAt list i)) (builtins.length list);
in
{
  inherit
    range
    unique
    flatten
    sum
    findFirst
    imap0
    ;
}
