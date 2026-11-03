# 最基本的函数组合子。
{
  # 原样返回参数。
  id = x: x;

  # 忽略第二个参数，总是返回第一个。
  const = x: _: x;

  # 交换二元函数的两个参数。
  flip =
    f: a: b:
    f b a;

  # 把值依次送过一串函数：pipe 1 [ f g ] == g (f 1)。
  pipe = builtins.foldl' (x: f: f x);
}
