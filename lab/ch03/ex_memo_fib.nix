# 练习答案：用惰性列表做记忆化的斐波那契。
# memo 是一个自己引用自己的列表，每个元素只算一次（共享的 thunk）。
let
  memo = builtins.genList (
    n: if n < 2 then n else builtins.elemAt memo (n - 1) + builtins.elemAt memo (n - 2)
  ) 81;
  naive = n: if n < 2 then n else naive (n - 1) + naive (n - 2);
in
{
  # 第 80 项：瞬间完成。
  fib80 = builtins.elemAt memo 80;
  # 朴素递归 fib 25 要调用 24 万多次；时间对比见 fib_timing.sh，
  # 这里只验证两种写法结果一致。
  fib25Naive = naive 25;
  fib25Memo = builtins.elemAt memo 25;
}
