# Firn lib 的测试：名字以 test 开头的属性是 { expr; expected; }，
# 结果是 runTests 返回的失败列表，`[ ]` 表示全部通过。
let
  lib = import ../lib;
  cases = {
    testId = {
      expr = lib.id 3;
      expected = 3;
    };
    testConst = {
      expr = lib.const 1 2;
      expected = 1;
    };
    testFlip = {
      expr = lib.flip builtins.sub 1 10;
      expected = 9;
    };
    testAttrByPathHit = {
      expr = lib.attrByPath [ "a" "b" ] 0 { a.b = 5; };
      expected = 5;
    };
    testAttrByPathMiss = {
      expr = lib.attrByPath [ "a" "x" ] 0 { a.b = 5; };
      expected = 0;
    };
    testAttrByPathThroughNonSet = {
      expr = lib.attrByPath [ "a" "b" ] "d" { a = 1; };
      expected = "d";
    };
    testAttrByPathEmpty = {
      expr = lib.attrByPath [ ] 0 { a = 1; };
      expected = {
        a = 1;
      };
    };
    testHasAttrByPathYes = {
      expr = lib.hasAttrByPath [ "a" "b" ] { a.b = null; };
      expected = true;
    };
    testHasAttrByPathNo = {
      expr = lib.hasAttrByPath [ "a" "c" ] { a.b = 1; };
      expected = false;
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
    testSetAttrByPathEmpty = {
      expr = lib.setAttrByPath [ ] 7;
      expected = 7;
    };
    testRecursiveUpdateKeeps = {
      expr = lib.recursiveUpdate { a.b = 1; } { a.c = 2; };
      expected = {
        a = {
          b = 1;
          c = 2;
        };
      };
    };
    testRecursiveUpdateOverrides = {
      expr = lib.recursiveUpdate { a.b = 1; } { a.b = 2; };
      expected = {
        a.b = 2;
      };
    };
    testRecursiveUpdateNonSetWins = {
      expr = lib.recursiveUpdate { a.b = 1; } { a = 3; };
      expected = {
        a = 3;
      };
    };
    testRecursiveUpdateNewKey = {
      expr = lib.recursiveUpdate { a = 1; } { b = 2; };
      expected = {
        a = 1;
        b = 2;
      };
    };
    testVersion = {
      expr = lib.version;
      expected = "0.1.0";
    };
    testFlatEqualsSubset = {
      expr = lib.attrsets.attrByPath [ "a" ] 0 { a = 1; };
      expected = lib.attrByPath [ "a" ] 0 { a = 1; };
    };
    testRecursiveUpdateThreeLevels = {
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
    testConstIgnoresSecond = {
      expr = lib.const "x" (throw "never forced");
      expected = "x";
    };
    testPipeOrder = {
      expr = lib.pipe 3 [
        (x: x + 1)
        (x: x * 10)
        toString
      ];
      expected = "40";
    };
    testPipeEmpty = {
      expr = lib.pipe 7 [ ];
      expected = 7;
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
    testFixLazyUnused = {
      expr =
        (lib.fix (_: {
          a = 1;
          bad = throw "never forced";
        })).a;
      expected = 1;
    };
    testExtendsOverridesDependents = {
      expr =
        (lib.fix (
          lib.extends (_: _: { a = 10; }) (self: {
            a = 1;
            b = self.a + 1;
          })
        )).b;
      expected = 11;
    };
    testExtendsSeesPrev = {
      expr =
        (lib.fix (
          lib.extends (_: prev: { a = prev.a + 5; }) (_: {
            a = 1;
          })
        )).a;
      expected = 6;
    };
    testComposeExtensionsOrder = {
      expr =
        (lib.fix (
          lib.extends (lib.composeExtensions (_: prev: { a = prev.a + 1; }) (_: prev: { a = prev.a * 10; }))
            (_: {
              a = 1;
            })
        )).a;
      expected = 20;
    };
    testComposeManyExtensionsOrder = {
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
    testComposeManyExtensionsEmpty = {
      expr =
        (lib.fix (
          lib.extends (lib.composeManyExtensions [ ]) (_: {
            a = 1;
          })
        )).a;
      expected = 1;
    };
    testMakeExtensibleExtend = {
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
    testMakeExtensibleChained = {
      expr =
        let
          base = lib.makeExtensible (_: {
            a = 1;
          });
        in
        ((base.extend (_: prev: { a = prev.a + 1; })).extend (_: prev: { a = prev.a * 10; })).a;
      expected = 20;
    };
    testHasPrefixYes = {
      expr = lib.hasPrefix "ab" "abc";
      expected = true;
    };
    testHasPrefixLonger = {
      expr = lib.hasPrefix "abcd" "abc";
      expected = false;
    };
    testHasSuffixYes = {
      expr = lib.hasSuffix "bc" "abc";
      expected = true;
    };
    testHasSuffixLonger = {
      expr = lib.hasSuffix "xabc" "abc";
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
    testSplitStringRegexChar = {
      expr = lib.splitString "." "a.b.c";
      expected = [
        "a"
        "b"
        "c"
      ];
    };
    testSplitStringNoMatch = {
      expr = lib.splitString "," "abc";
      expected = [ "abc" ];
    };
    testConcatMapStringsSepBasic = {
      expr = lib.concatMapStringsSep "-" toString [
        1
        2
        3
      ];
      expected = "1-2-3";
    };
    testEscapeShellArgPlain = {
      expr = lib.escapeShellArg "a b";
      expected = "'a b'";
    };
    testEscapeShellArgQuote = {
      expr = lib.escapeShellArg "it's";
      expected = "'it'\\''s'";
    };
    testImportTOMLChapters = {
      expr = builtins.length (lib.importTOML ../data/chapters.toml).chapters;
      expected = 20;
    };
    testImportJSONFixture = {
      expr = lib.importJSON (builtins.toFile "x.json" ''{"a":[1,2]}'');
      expected = {
        a = [
          1
          2
        ];
      };
    };
    testReadLinesNoTrailingEmpty = {
      expr = lib.readLines (builtins.toFile "x.txt" "a\nb\n");
      expected = [
        "a"
        "b"
      ];
    };
    testReadLinesKeepsInnerEmpty = {
      expr = lib.readLines (builtins.toFile "y.txt" "a\n\nb");
      expected = [
        "a"
        ""
        "b"
      ];
    };
    testRenderChapterTableTwoRows = {
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
    testCleanSourceKeepsRegularFiles = {
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
    testRangeBasic = {
      expr = lib.range 2 5;
      expected = [
        2
        3
        4
        5
      ];
    };
    testRangeSingle = {
      expr = lib.range 3 3;
      expected = [ 3 ];
    };
    testRangeEmpty = {
      expr = lib.range 5 2;
      expected = [ ];
    };
    testUniqueKeepsFirst = {
      expr = lib.unique [
        3
        1
        3
        2
        1
      ];
      expected = [
        3
        1
        2
      ];
    };
    testUniqueEmpty = {
      expr = lib.unique [ ];
      expected = [ ];
    };
    testFlattenNested = {
      expr = lib.flatten [
        1
        [
          2
          [ 3 ]
        ]
        [ ]
      ];
      expected = [
        1
        2
        3
      ];
    };
    testFlattenScalar = {
      expr = lib.flatten 1;
      expected = [ 1 ];
    };
    testSumBasic = {
      expr = lib.sum [
        1
        2
        3
        4
      ];
      expected = 10;
    };
    testSumEmpty = {
      expr = lib.sum [ ];
      expected = 0;
    };
    testFindFirstHit = {
      expr = lib.findFirst (x: x > 2) 0 [
        1
        3
        5
      ];
      expected = 3;
    };
    testFindFirstMiss = {
      expr = lib.findFirst (x: x > 9) 0 [
        1
        3
      ];
      expected = 0;
    };
    testFindFirstLazyTail = {
      expr = lib.findFirst (x: x == 1) 0 [
        1
        (throw "never forced")
      ];
      expected = 1;
    };
    testImap0Index = {
      expr = lib.imap0 (i: x: "${toString i}${x}") [
        "a"
        "b"
      ];
      expected = [
        "0a"
        "1b"
      ];
    };
    testNameValuePair = {
      expr = lib.nameValuePair "k" 1;
      expected = {
        name = "k";
        value = 1;
      };
    };
    testGenAttrs = {
      expr = lib.genAttrs [ "a" "bb" ] builtins.stringLength;
      expected = {
        a = 1;
        bb = 2;
      };
    };
    testMapAttrsToListSorted = {
      expr = lib.mapAttrsToList (n: v: "${n}=${toString v}") {
        b = 2;
        a = 1;
      };
      expected = [
        "a=1"
        "b=2"
      ];
    };
    testFilterAttrs = {
      expr = lib.filterAttrs (_: v: v > 1) {
        a = 1;
        b = 2;
        c = 3;
      };
      expected = {
        b = 2;
        c = 3;
      };
    };
    testMapAttrsPrime = {
      expr = lib.mapAttrs' (n: v: lib.nameValuePair "x${n}" (v + 1)) {
        a = 1;
        b = 2;
      };
      expected = {
        xa = 2;
        xb = 3;
      };
    };
    testToKeyValueAttrsetSorted = {
      expr = lib.toKeyValue { } {
        b = 2;
        a = "x";
      };
      expected = "a = x\nb = 2\n";
    };
    testToKeyValueListOrder = {
      expr = lib.toKeyValue { } [
        (lib.nameValuePair "z" 1)
        (lib.nameValuePair "a" 2)
      ];
      expected = "z = 1\na = 2\n";
    };
    testToKeyValueListValue = {
      expr = lib.toKeyValue { } {
        source = [
          "/a"
          "/b"
        ];
      };
      expected = "source = /a\nsource = /b\n";
    };
    testToKeyValueBool = {
      expr = lib.toKeyValue { } {
        off = false;
        on = true;
      };
      expected = "off = false\non = true\n";
    };
    testToKeyValueSep = {
      expr = lib.toKeyValue { sep = "="; } { a = 1; };
      expected = "a=1\n";
    };
    testToINI = {
      expr = lib.toINI { } {
        s = {
          k = 1;
        };
        t = {
          x = "y";
        };
      };
      expected = "[s]\nk = 1\n\n[t]\nx = y\n";
    };
    testRunTestsIgnoresNonTest = {
      expr = lib.runTests {
        helper = {
          expr = 1;
          expected = 2;
        };
      };
      expected = [ ];
    };
    testRunTestsReportsFailure = {
      expr = lib.runTests {
        testBad = {
          expr = 1;
          expected = 2;
        };
        testGood = {
          expr = 1;
          expected = 1;
        };
      };
      expected = [
        {
          name = "testBad";
          expected = 2;
          result = 1;
        }
      ];
    };
    testTextStorePathEmpty = {
      expr = lib.storePath.textStorePath {
        name = "empty";
        content = "";
      };
      expected = builtins.toFile "empty" "";
    };
    testTextStorePathPlain = {
      expr = lib.textStorePath {
        name = "hello.txt";
        content = "hello, firn\n";
      };
      expected = builtins.toFile "hello.txt" "hello, firn\n";
    };
    testTextStorePathWithReference =
      let
        dep = builtins.toFile "dep" "dependency";
        content = "needs ${dep}\n";
      in
      {
        expr = lib.textStorePath {
          name = "user";
          inherit content;
          references = [ dep ];
        };
        expected = builtins.toFile "user" content;
      };
    testTextStorePathReferenceMatters =
      let
        dep = builtins.toFile "dep" "dependency";
        content = "needs ${dep}\n";
      in
      {
        expr =
          lib.textStorePath {
            name = "user";
            inherit content;
          } == builtins.toFile "user" content;
        expected = false;
      };
  };
  failed = lib.runTests cases;
in
failed
