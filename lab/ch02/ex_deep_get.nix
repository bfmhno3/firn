# 练习答案：不用 lib 实现 attrByPath，并和 Firn 的版本对拍。
let
  lib = import ../../lib;
  get =
    path: default: set:
    if path == [ ] then
      set
    else if builtins.isAttrs set && set ? ${builtins.head path} then
      get (builtins.tail path) default set.${builtins.head path}
    else
      default;
  data = {
    a.b.c = 1;
    a.s = "str";
  };
  probes = [
    [
      "a"
      "b"
      "c"
    ]
    [
      "a"
      "b"
      "x"
    ]
    [
      "a"
      "s"
      "t"
    ]
    [ ]
    [ "q" ]
  ];
in
assert builtins.all (p: get p "dflt" data == lib.attrByPath p "dflt" data) probes;
map (p: get p "dflt" data) probes
