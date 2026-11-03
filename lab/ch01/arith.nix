# 整数除法截断，浮点除法不截断；`/` 两边只要有一个浮点数，结果就是浮点数。
{
  add = 1 + 2;
  intDiv = 7 / 2;
  floatDiv = 7.0 / 2;
  builtinDiv = builtins.div 7 2;
  negDiv = -7 / 2;
  mixedMul = 2 * 3.0;
  ceil = builtins.ceil 2.5;
}
