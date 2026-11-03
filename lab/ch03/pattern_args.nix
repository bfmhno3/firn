# 属性集模式参数：默认值、`...`、`@` 别名，以及 functionArgs 的返回值。
# callPackage（第 7、10 章）就靠 functionArgs 知道一个函数要什么。
let
  f =
    {
      a,
      b ? 2,
      ...
    }@args:
    {
      sum = a + b;
      received = builtins.attrNames args;
    };
  strict = { a, b }: a + b;
in
{
  functionArgs = builtins.functionArgs f;
  strictArgs = builtins.functionArgs strict;
  plainLambdaArgs = builtins.functionArgs (x: x);
  withDefault = f { a = 1; };
  overrideDefault = f {
    a = 1;
    b = 10;
  };
  extraAllowed = f {
    a = 1;
    extra = true;
  };
}
