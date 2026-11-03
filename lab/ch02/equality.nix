# == 对集合和列表是深度比较；函数永远不相等；1 == 1.0。
{
  setsEqual =
    {
      a = [
        1
        { b = 2; }
      ];
    } == {
      a = [
        1
        { b = 2; }
      ];
    };
  keyOrderIrrelevant =
    {
      a = 1;
      b = 2;
    } == {
      b = 2;
      a = 1;
    };
  listsEqual =
    [
      1
      2
      [ 3 ]
    ] == [
      1
      2
      [ 3 ]
    ];
  listOrderMatters =
    [
      1
      2
    ] == [
      2
      1
    ];
  lambdas = (x: x) == (x: x);
  sameLambda =
    let
      f = x: x;
    in
    f == f;
  intFloat = 1 == 1.0;
  stringPath = "/tmp" == /tmp;
  nullEq = null == null;
  differentTypes = 1 == "1";
}
