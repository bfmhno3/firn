# 用嵌套的惰性属性集表示无穷的自然数流，只求值取走的部分。
let
  from = n: {
    head = n;
    tail = from (n + 1);
  };
  take = n: s: if n == 0 then [ ] else [ s.head ] ++ take (n - 1) s.tail;
in
take 10 (from 0)
