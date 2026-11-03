# 每种值类型各取一个，看 builtins.typeOf 怎么说。
{
  int = builtins.typeOf 1;
  float = builtins.typeOf 1.5;
  bool = builtins.typeOf true;
  string = builtins.typeOf "s";
  path = builtins.typeOf ./.;
  null = builtins.typeOf null;
  list = builtins.typeOf [ 1 ];
  set = builtins.typeOf { };
  lambda = builtins.typeOf (x: x);
  builtinCount = builtins.length (builtins.attrNames builtins);
}
