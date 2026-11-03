# Nix 的函数只有一个参数：多参数函数是返回函数的函数，所以可以部分应用。
let
  add = a: b: a + b;
  addOne = add 1;
  compose =
    f: g: x:
    f (g x);
in
{
  full = add 1 2;
  partial = addOne 41;
  mapped = map (add 10) [
    1
    2
    3
  ];
  composed = (compose (x: x * 2) addOne) 5;
  # 参数个数没有区别：这个“三参数函数”就是三层 lambda。
  threeLayers =
    (
      a: b: c:
      a + b * c
    )
      1
      2
      3;
  isFunction = builtins.isFunction add;
}
