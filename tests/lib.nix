# Firn lib 的第一版测试：每个用例是 { expr; expected; }，
# 结果是失败用例的列表，`[ ]` 表示全部通过。第 5 章改用 runTests。
let
  lib = import ../lib;
  cases = {
    id = {
      expr = lib.id 3;
      expected = 3;
    };
    const = {
      expr = lib.const 1 2;
      expected = 1;
    };
    flip = {
      expr = lib.flip builtins.sub 1 10;
      expected = 9;
    };
    attrByPathHit = {
      expr = lib.attrByPath [ "a" "b" ] 0 { a.b = 5; };
      expected = 5;
    };
    attrByPathMiss = {
      expr = lib.attrByPath [ "a" "x" ] 0 { a.b = 5; };
      expected = 0;
    };
    attrByPathThroughNonSet = {
      expr = lib.attrByPath [ "a" "b" ] "d" { a = 1; };
      expected = "d";
    };
    attrByPathEmpty = {
      expr = lib.attrByPath [ ] 0 { a = 1; };
      expected = {
        a = 1;
      };
    };
    hasAttrByPathYes = {
      expr = lib.hasAttrByPath [ "a" "b" ] { a.b = null; };
      expected = true;
    };
    hasAttrByPathNo = {
      expr = lib.hasAttrByPath [ "a" "c" ] { a.b = 1; };
      expected = false;
    };
    hasAttrByPathNonSet = {
      expr = lib.hasAttrByPath [ "a" "b" ] { a = "s"; };
      expected = false;
    };
    setAttrByPathDeep = {
      expr = lib.setAttrByPath [ "a" "b" "c" ] 1;
      expected = {
        a.b.c = 1;
      };
    };
    setAttrByPathEmpty = {
      expr = lib.setAttrByPath [ ] 7;
      expected = 7;
    };
    recursiveUpdateKeeps = {
      expr = lib.recursiveUpdate { a.b = 1; } { a.c = 2; };
      expected = {
        a = {
          b = 1;
          c = 2;
        };
      };
    };
    recursiveUpdateOverrides = {
      expr = lib.recursiveUpdate { a.b = 1; } { a.b = 2; };
      expected = {
        a.b = 2;
      };
    };
    recursiveUpdateNonSetWins = {
      expr = lib.recursiveUpdate { a.b = 1; } { a = 3; };
      expected = {
        a = 3;
      };
    };
    recursiveUpdateNewKey = {
      expr = lib.recursiveUpdate { a = 1; } { b = 2; };
      expected = {
        a = 1;
        b = 2;
      };
    };
    version = {
      expr = lib.version;
      expected = "0.1.0";
    };
    flatEqualsSubset = {
      expr = lib.attrsets.attrByPath [ "a" ] 0 { a = 1; };
      expected = lib.attrByPath [ "a" ] 0 { a = 1; };
    };
    recursiveUpdateThreeLevels = {
      expr = lib.recursiveUpdate {
        a.b.c = 1;
        a.b.d = 2;
      } { a.b.c = 9; };
      expected = {
        a.b = {
          c = 9;
          d = 2;
        };
      };
    };
    constIgnoresSecond = {
      expr = lib.const "x" (throw "never forced");
      expected = "x";
    };
  };
  failed = builtins.filter (t: t.expr != t.expected) (
    builtins.attrValues (builtins.mapAttrs (name: t: t // { inherit name; }) cases)
  );
in
failed
