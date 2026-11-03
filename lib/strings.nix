# 字符串工具，只依赖 builtins。
let
  hasPrefix = prefix: s: builtins.substring 0 (builtins.stringLength prefix) s == prefix;

  hasSuffix =
    suffix: s:
    let
      sLen = builtins.stringLength s;
      suffixLen = builtins.stringLength suffix;
    in
    sLen >= suffixLen && builtins.substring (sLen - suffixLen) suffixLen s == suffix;

  # builtins.split 的第一个参数是正则，分隔符里的元字符要先转义。
  escapeRegex =
    builtins.replaceStrings
      [
        "\\"
        "."
        "["
        "]"
        "("
        ")"
        "{"
        "}"
        "*"
        "+"
        "?"
        "|"
        "^"
        "$"
      ]
      [
        "\\\\"
        "\\."
        "\\["
        "\\]"
        "\\("
        "\\)"
        "\\{"
        "\\}"
        "\\*"
        "\\+"
        "\\?"
        "\\|"
        "\\^"
        "\\$"
      ];

  # splitString "," "a,b,,c" == [ "a" "b" "" "c" ]；分隔符不能为空。
  splitString =
    sep: s:
    if sep == "" then
      throw "firn: splitString: separator must not be empty"
    else
      builtins.filter builtins.isString (builtins.split (escapeRegex sep) s);

  concatMapStringsSep =
    sep: f: list:
    builtins.concatStringsSep sep (map f list);

  # 用单引号包起来，字符串内部的单引号写成 '\'' 。
  escapeShellArg = arg: "'${builtins.replaceStrings [ "'" ] [ "'\\''" ] (toString arg)}'";
in
{
  inherit
    hasPrefix
    hasSuffix
    splitString
    concatMapStringsSep
    escapeShellArg
    ;
}
