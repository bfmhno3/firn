# builtins.trace 把消息写到 stderr，从中能看出求值顺序（和书写顺序无关）。
let
  a = builtins.trace "forcing a" 1;
  b = builtins.trace "forcing b" 2;
  unused = builtins.trace "forcing unused" 3;
in
# 先用 b，再用 a；unused 永远不出现。重复使用 a 不会重复打印（共享）。
(b + a) + a
