# with 的优先级最低：let 和函数参数永远赢，内层 with 赢外层 with。
let
  x = "let";
in
{
  letBeatsWith = with { x = "with"; }; x;
  innerWins = with { y = "outer"; }; with { y = "inner"; }; y;
  outerStillVisible = with { p = "p-outer"; }; with { q = "q-inner"; }; "${p} ${q}";
  # BAD: 文件级 with 让读者无法知道名字从哪里来；风格规则禁止。
  silentShadow = with { x = "with"; }; x;
}
