# 十四个 Firn lib 函数和 nixpkgs lib 同一组输入的结果逐一比较，
# 任何一项不同就让求值失败（退出码非零）。
let
  firn = import ../../lib;
  nixpkgsLib = import "${(import ../../nix/pins.nix).nixpkgs}/lib";
  cases = {
    attrByPath = f: f.attrByPath [ "a" "b" ] 0 { a.b = 5; };
    hasAttrByPath = f: f.hasAttrByPath [ "a" "c" ] { a.b = 1; };
    setAttrByPath = f: f.setAttrByPath [ "a" "b" ] 1;
    recursiveUpdate =
      f:
      f.recursiveUpdate {
        a.b = 1;
        c = 1;
      } { a.d = 2; };
    genAttrs = f: f.genAttrs [ "a" "bb" ] builtins.stringLength;
    mapAttrsToList =
      f:
      f.mapAttrsToList (n: v: "${n}=${toString v}") {
        b = 2;
        a = 1;
      };
    filterAttrs =
      f:
      f.filterAttrs (_: v: v > 1) {
        a = 1;
        b = 2;
      };
    range = f: f.range 2 6;
    unique =
      f:
      f.unique [
        3
        1
        3
        2
        1
      ];
    flatten =
      f:
      f.flatten [
        1
        [
          2
          [ 3 ]
        ]
      ];
    splitString = f: f.splitString "," "a,b,,c";
    hasPrefix = f: f.hasPrefix "ab" "abc";
    imap0 =
      f:
      f.imap0 (i: x: "${toString i}${x}") [
        "a"
        "b"
      ];
    findFirst =
      f:
      f.findFirst (x: x > 2) 0 [
        1
        3
        5
      ];
  };
  results = builtins.mapAttrs (
    name: run:
    let
      ours = run firn;
      theirs = run nixpkgsLib;
    in
    {
      inherit ours theirs;
      same = ours == theirs;
    }
  ) cases;
  mismatches = builtins.attrNames (
    builtins.removeAttrs results (builtins.filter (n: results.${n}.same) (builtins.attrNames results))
  );
in
if mismatches == [ ] then
  builtins.mapAttrs (_: r: r.ours) results
else
  throw "Firn lib differs from nixpkgs lib for: ${builtins.concatStringsSep ", " mismatches}"
