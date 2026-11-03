# attrset 的语法：rec、inherit、//、?、or、动态键，以及 a.b.c 嵌套糖。
let
  x = {
    a = 1;
    b = 2;
  };
  a = 10;
  name = "dyn";
in
{
  recSet = rec {
    p = 1;
    q = p + 1;
  };
  inheritPlain =
    let
      inherit a;
    in
    {
      inherit a;
    };
  inheritFrom = {
    inherit (x) a b;
  };
  update = x // {
    b = 20;
    c = 30;
  };
  hasA = x ? a;
  hasZ = x ? z;
  orDefault = x.z or "fallback";
  orNested = x.a.deep.er or "no deeper";
  dynamicKey = {
    ${name} = 1;
    "${name}-2" = 2;
  };
  sugar = {
    a.b.c = 1;
  };
  # 两行 a.b.* 在同一个属性集里会合并，而不是冲突。
  sugarMerge = {
    a.b.c = 1;
    a.b.d = 2;
    a.e = 3;
  };
  sugarEqualsNested =
    {
      a.b.c = 1;
    } == {
      a = {
        b = {
          c = 1;
        };
      };
    };
}
