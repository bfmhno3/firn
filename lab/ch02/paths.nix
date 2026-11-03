# 路径是一等类型：相对路径按所在文件的目录解析，插值时被复制进 store。
{
  relative = ./fixtures/note.txt;
  type = builtins.typeOf ./fixtures/note.txt;
  appended = ./. + "/fixtures";
  dirOfThisFile = toString ./.;
  exists = builtins.pathExists ./fixtures/note.txt;
  content = builtins.readFile ./fixtures/note.txt;
  # 插值把文件复制到 store，字符串里是 store 路径。
  interpolated = "${./fixtures/note.txt}";
  stringIsNotPath = builtins.typeOf "${./fixtures/note.txt}";
  # 字符串形式的路径不会被复制，也不会随文件所在目录解析。
  plainString = builtins.typeOf "./fixtures/note.txt";
}
