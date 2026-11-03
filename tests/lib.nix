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
    pipeOrder = {
      expr = lib.pipe 3 [
        (x: x + 1)
        (x: x * 10)
        toString
      ];
      expected = "40";
    };
    pipeEmpty = {
      expr = lib.pipe 7 [ ];
      expected = 7;
    };
    fixSelfReference = {
      expr = lib.fix (self: {
        a = 1;
        b = self.a + 1;
      });
      expected = {
        a = 1;
        b = 2;
      };
    };
    fixLazyUnused = {
      expr =
        (lib.fix (_: {
          a = 1;
          bad = throw "never forced";
        })).a;
      expected = 1;
    };
    extendsOverridesDependents = {
      expr =
        (lib.fix (
          lib.extends (_: _: { a = 10; }) (self: {
            a = 1;
            b = self.a + 1;
          })
        )).b;
      expected = 11;
    };
    extendsSeesPrev = {
      expr =
        (lib.fix (
          lib.extends (_: prev: { a = prev.a + 5; }) (_: {
            a = 1;
          })
        )).a;
      expected = 6;
    };
    composeExtensionsOrder = {
      expr =
        (lib.fix (
          lib.extends (lib.composeExtensions (_: prev: { a = prev.a + 1; }) (_: prev: { a = prev.a * 10; }))
            (_: {
              a = 1;
            })
        )).a;
      expected = 20;
    };
    composeManyExtensionsOrder = {
      expr =
        (lib.fix (
          lib.extends
            (lib.composeManyExtensions [
              (_: prev: { a = prev.a + 1; })
              (_: prev: { a = prev.a * 10; })
              (_: prev: { a = prev.a - 3; })
            ])
            (_: {
              a = 1;
            })
        )).a;
      expected = 17;
    };
    composeManyExtensionsEmpty = {
      expr =
        (lib.fix (
          lib.extends (lib.composeManyExtensions [ ]) (_: {
            a = 1;
          })
        )).a;
      expected = 1;
    };
    makeExtensibleExtend = {
      expr =
        let
          base = lib.makeExtensible (self: {
            a = 1;
            b = self.a + 1;
          });
        in
        (base.extend (_: _: { a = 10; })).b;
      expected = 11;
    };
    makeExtensibleChained = {
      expr =
        let
          base = lib.makeExtensible (_: {
            a = 1;
          });
        in
        ((base.extend (_: prev: { a = prev.a + 1; })).extend (_: prev: { a = prev.a * 10; })).a;
      expected = 20;
    };
    hasPrefixYes = {
      expr = lib.hasPrefix "ab" "abc";
      expected = true;
    };
    hasPrefixLonger = {
      expr = lib.hasPrefix "abcd" "abc";
      expected = false;
    };
    hasSuffixYes = {
      expr = lib.hasSuffix "bc" "abc";
      expected = true;
    };
    hasSuffixLonger = {
      expr = lib.hasSuffix "xabc" "abc";
      expected = false;
    };
    splitStringBasic = {
      expr = lib.splitString "," "a,b,,c";
      expected = [
        "a"
        "b"
        ""
        "c"
      ];
    };
    splitStringRegexChar = {
      expr = lib.splitString "." "a.b.c";
      expected = [
        "a"
        "b"
        "c"
      ];
    };
    splitStringNoMatch = {
      expr = lib.splitString "," "abc";
      expected = [ "abc" ];
    };
    concatMapStringsSepBasic = {
      expr = lib.concatMapStringsSep "-" toString [
        1
        2
        3
      ];
      expected = "1-2-3";
    };
    escapeShellArgPlain = {
      expr = lib.escapeShellArg "a b";
      expected = "'a b'";
    };
    escapeShellArgQuote = {
      expr = lib.escapeShellArg "it's";
      expected = "'it'\\''s'";
    };
    importTOMLChapters = {
      expr = builtins.length (lib.importTOML ../data/chapters.toml).chapters;
      expected = 20;
    };
    importJSONFixture = {
      expr = lib.importJSON (builtins.toFile "x.json" ''{"a":[1,2]}'');
      expected = {
        a = [
          1
          2
        ];
      };
    };
    readLinesNoTrailingEmpty = {
      expr = lib.readLines (builtins.toFile "x.txt" "a\nb\n");
      expected = [
        "a"
        "b"
      ];
    };
    readLinesKeepsInnerEmpty = {
      expr = lib.readLines (builtins.toFile "y.txt" "a\n\nb");
      expected = [
        "a"
        ""
        "b"
      ];
    };
    renderChapterTableTwoRows = {
      expr = lib.renderChapterTable [
        {
          n = 1;
          stem = "s1";
          title = "T1";
        }
        {
          n = 12;
          stem = "s12";
          title = "T12";
        }
      ];
      expected = "| Chapter | Topic | Post |\n| --- | --- | --- |\n| `ch01` | T1 | `/posts/s1/` |\n| `ch12` | T12 | `/posts/s12/` |\n";
    };
    cleanSourceKeepsRegularFiles = {
      expr =
        let
          src = lib.cleanSource ../lab/ch04/fixtures;
        in
        builtins.attrNames (builtins.readDir src);
      expected = [
        "adder.nix"
        "dir"
        "gen.nix"
        "traced.nix"
      ];
    };
  };
  failed = builtins.filter (t: t.expr != t.expected) (
    builtins.attrValues (builtins.mapAttrs (name: t: t // { inherit name; }) cases)
  );
in
failed
