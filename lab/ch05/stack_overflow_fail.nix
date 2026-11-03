# 朴素递归 sumTo 1000000 一定失败：调用深度超过 max-call-depth（默认 10000），
# 求值器抛出 `stack overflow; max-call-depth exceeded`。
let
  sumTo = n: if n == 0 then 0 else n + sumTo (n - 1);
in
sumTo 1000000
