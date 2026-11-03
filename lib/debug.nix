# 调试与测试工具。runTests 的约定和 nixpkgs 的 lib.debug.runTests 相同。
let
  # tests 是属性集，名字以 test 开头的属性必须是 { expr; expected; }。
  # 返回失败用例的列表，每项是 { name; expected; result; }；空列表表示全部通过。
  runTests =
    tests:
    builtins.concatLists (
      builtins.attrValues (
        builtins.mapAttrs (
          name: test:
          if builtins.substring 0 4 name == "test" && test.expr != test.expected then
            [
              {
                inherit name;
                inherit (test) expected;
                result = test.expr;
              }
            ]
          else
            [ ]
        ) tests
      )
    );
in
{
  inherit runTests;
}
