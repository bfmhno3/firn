# 读取数据文件的小工具：JSON、TOML 和按行读取。
let
  strings = import ./strings.nix;

  importJSON = path: builtins.fromJSON (builtins.readFile path);

  importTOML = path: builtins.fromTOML (builtins.readFile path);

  # 按行切开；文件末尾的换行不产生多余的空行。
  readLines =
    path:
    let
      lines = strings.splitString "\n" (builtins.readFile path);
      count = builtins.length lines;
    in
    if count > 0 && builtins.elemAt lines (count - 1) == "" then
      builtins.genList (builtins.elemAt lines) (count - 1)
    else
      lines;
in
{
  inherit importJSON importTOML readLines;
}
