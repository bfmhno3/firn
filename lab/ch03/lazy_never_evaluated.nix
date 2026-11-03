# 没用到的东西不会被求值，包括会报错的东西。
let
  x = throw "boom";
in
{
  unusedLet = 1;
  listLength = builtins.length [
    (throw "a")
    (throw "b")
  ];
  unusedAttr =
    {
      bad = abort "never reached";
      good = 2;
    }
    .good;
  # 函数参数也是惰性的。
  ignoresArg = (_: "done") (throw "arg");
  # && 短路，右边不求值。
  shortCircuit = false && throw "rhs";
  # if 只求值被选中的分支。
  branch = if true then "then" else throw "else";
}
