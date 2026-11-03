# readDir 返回 { 文件名 = 类型; }，类型是 "regular"、"directory"、"symlink" 或 "unknown"。
# attrNames 按字典序排序，所以输出顺序稳定。
let
  entries = builtins.readDir ../ch02;
in
{
  inherit entries;
  names = builtins.attrNames entries;
  directories = builtins.attrNames (
    builtins.removeAttrs entries (
      builtins.filter (n: entries.${n} != "directory") (builtins.attrNames entries)
    )
  );
  exists = {
    present = builtins.pathExists ../ch02/types.nix;
    absent = builtins.pathExists ../ch02/nope.nix;
  };
  fileType = builtins.readFileType ../ch02/fixtures;
}
