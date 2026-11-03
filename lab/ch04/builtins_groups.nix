# builtins 目录的分组：每个名字恰好属于一组，没归类的和写错的名字都会报错。
# 在 `--file` 下运行（不纯），所以包含 currentSystem 和 currentTime 共 118 个名字；
# 纯模式的 `--expr` 少这两个。
let
  groups = {
    types = [
      "isAttrs"
      "isBool"
      "isFloat"
      "isFunction"
      "isInt"
      "isList"
      "isNull"
      "isPath"
      "isString"
      "typeOf"
    ];
    arithmetic = [
      "add"
      "sub"
      "mul"
      "div"
      "lessThan"
      "ceil"
      "floor"
      "bitAnd"
      "bitOr"
      "bitXor"
    ];
    strings = [
      "stringLength"
      "substring"
      "replaceStrings"
      "concatStringsSep"
      "split"
      "match"
      "toString"
      "compareVersions"
      "splitVersion"
      "parseDrvName"
    ];
    lists = [
      "all"
      "any"
      "concatLists"
      "concatMap"
      "elem"
      "elemAt"
      "filter"
      "foldl'"
      "genList"
      "genericClosure"
      "groupBy"
      "head"
      "length"
      "map"
      "partition"
      "sort"
      "tail"
    ];
    attrsets = [
      "attrNames"
      "attrValues"
      "catAttrs"
      "functionArgs"
      "getAttr"
      "hasAttr"
      "intersectAttrs"
      "listToAttrs"
      "mapAttrs"
      "removeAttrs"
      "zipAttrsWith"
    ];
    control = [
      "abort"
      "throw"
      "warn"
      "trace"
      "traceVerbose"
      "tryEval"
      "seq"
      "deepSeq"
      "break"
      "addErrorContext"
      "unsafeGetAttrPos"
    ];
    files = [
      "baseNameOf"
      "dirOf"
      "path"
      "filterSource"
      "pathExists"
      "readDir"
      "readFile"
      "readFileType"
      "toPath"
      "storePath"
      "toFile"
      "findFile"
      "import"
      "scopedImport"
    ];
    serialization = [
      "fromJSON"
      "toJSON"
      "fromTOML"
      "toXML"
    ];
    hashing = [
      "hashString"
      "hashFile"
      "convertHash"
    ];
    fetchers = [
      "fetchurl"
      "fetchTarball"
      "fetchGit"
      "fetchMercurial"
      "fetchTree"
      "getFlake"
      "parseFlakeRef"
      "flakeRefToString"
    ];
    derivations = [
      "derivation"
      "derivationStrict"
      "placeholder"
      "getContext"
      "hasContext"
      "appendContext"
      "unsafeDiscardStringContext"
      "unsafeDiscardOutputDependency"
      "addDrvOutputDependencies"
    ];
    environment = [
      "builtins"
      "currentSystem"
      "currentTime"
      "getEnv"
      "langVersion"
      "nixPath"
      "nixVersion"
      "storeDir"
      "true"
      "false"
      "null"
    ];
  };
  all = builtins.attrNames builtins;
  grouped = builtins.concatLists (builtins.attrValues groups);
  missing = builtins.filter (n: !(builtins.hasAttr n builtins)) grouped;
  uncategorized = builtins.filter (n: !(builtins.elem n grouped)) all;
  duplicates = builtins.filter (n: builtins.length (builtins.filter (m: m == n) grouped) > 1) grouped;
  report = {
    total = builtins.length all;
    groupedTotal = builtins.length grouped;
    perGroup = builtins.mapAttrs (_: builtins.length) groups;
  };
in
assert missing == [ ] || throw "names not in builtins: ${toString missing}";
assert uncategorized == [ ] || throw "uncategorized builtins: ${toString uncategorized}";
assert duplicates == [ ] || throw "names in two groups: ${toString duplicates}";
report
