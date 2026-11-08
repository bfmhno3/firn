# 14 个用例：13 个取自 tests/lib.nix（testConstIsLazy 是那里的
# testConstIgnoresSecond 改了名），1 个是 nix-unit 才有的 expectedError。格式相同：testXxx = { expr; expected; }，
# 不同在运行方式：`nix-unit tests/lib-unit.nix` 逐个求值并打印每个用例的结果，
# 而 runTests 只返回失败列表。nix-unit 还多一种用例，`expectedError`，见最后一个。
let
  lib = import ../lib;
in
{
  testId = {
    expr = lib.id 3;
    expected = 3;
  };
  testFlip = {
    expr = lib.flip builtins.sub 1 10;
    expected = 9;
  };
  testAttrByPathHit = {
    expr = lib.attrByPath [ "a" "b" ] 0 { a.b = 5; };
    expected = 5;
  };
  testHasAttrByPathNonSet = {
    expr = lib.hasAttrByPath [ "a" "b" ] { a = "s"; };
    expected = false;
  };
  testSetAttrByPathDeep = {
    expr = lib.setAttrByPath [ "a" "b" "c" ] 1;
    expected = {
      a.b.c = 1;
    };
  };
  testRecursiveUpdateNonSetWins = {
    expr = lib.recursiveUpdate { a.b = 1; } { a = 3; };
    expected = {
      a = 3;
    };
  };
  testFixSelfReference = {
    expr = lib.fix (self: {
      a = 1;
      b = self.a + 1;
    });
    expected = {
      a = 1;
      b = 2;
    };
  };
  testHasPrefixLonger = {
    expr = lib.hasPrefix "abcd" "abc";
    expected = false;
  };
  testSplitStringBasic = {
    expr = lib.splitString "," "a,b,,c";
    expected = [
      "a"
      "b"
      ""
      "c"
    ];
  };
  testEscapeShellArgPlain = {
    expr = lib.escapeShellArg "a b";
    expected = "'a b'";
  };
  testRangeEmpty = {
    expr = lib.range 5 2;
    expected = [ ];
  };
  testGenAttrs = {
    expr = lib.genAttrs [ "a" "bb" ] builtins.stringLength;
    expected = {
      a = 1;
      bb = 2;
    };
  };
  testConstIsLazy = {
    expr = lib.const "x" (throw "never forced");
    expected = "x";
  };
  testThrowIsExpected = {
    expr = throw "boom";
    expectedError.type = "ThrownError";
    expectedError.msg = "boom";
  };
}
