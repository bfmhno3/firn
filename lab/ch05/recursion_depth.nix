# 朴素递归 sumTo 在 max-call-depth（默认 10000）以内可以正常求值：
# 深度 9999 是最后一个能过的值，10000 见 stack_overflow_fail.nix。
let
  sumTo = n: if n == 0 then 0 else n + sumTo (n - 1);
in
{
  depth = 9999;
  result = sumTo 9999;
  expected = 9999 * 10000 / 2;
}
