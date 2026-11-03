# a 依赖 b，b 依赖 a：求值器发现 thunk 正在求值自己（blackhole）就报错。
(rec {
  a = b;
  b = a;
}).a
