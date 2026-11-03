# 字符串：插值、'' 缩进剥离、转义、toString、toJSON。
let
  name = "firn";
in
{
  interpolated = "hello ${name}, 1 + 1 = ${toString (1 + 1)}";
  nested = "a${"b${"c"}"}";
  indented = ''
    first
      second (indented by 2)
    third
  '';
  escDollar = "cost: \${HOME} stays literal";
  escQuotes = "two single quotes: ''. done";
  escNewline = ''tab:''\tend'';
  plainEscape = "quote \" and backslash \\ and \${not}";
  toStringList = toString [
    1
    2
    3
  ];
  toStringTrue = toString true;
  toStringFalse = toString false;
  toStringNull = toString null;
  toStringInt = toString 42;
  toStringFloat = toString 1.5;
  toStringPath = toString ./.;
  toStringSet = toString { __toString = self: "from __toString"; };
  outPathSet = "${{ outPath = "/nix/store/fake"; }}";
  json = builtins.toJSON {
    n = 1;
    s = "x";
    l = [
      true
      null
    ];
  };
}
