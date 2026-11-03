# match 用 POSIX ERE，整个字符串必须匹配（隐含锚定），返回捕获组列表或 null。
# split 返回“字符串、捕获组列表、字符串……”交替的列表。
{
  full = builtins.match "ch([0-9]+)" "ch04";
  # 没有捕获组：匹配成功返回空列表。
  noGroups = builtins.match "ch[0-9]+" "ch04";
  # 不是整串匹配：null，而不是部分匹配。
  partial = builtins.match "[0-9]+" "ch04";
  noMatch = builtins.match "x" "ch04";
  twoGroups = builtins.match "([a-z]+)-([0-9]+)" "nix-2";
  # 没参与匹配的可选组是 null。
  optionalGroup = builtins.match "a(b)?c" "ac";
  # 要做“包含”判断，两端加 .*。
  contains = builtins.match ".*ix.*" "nix" != null;
  split = builtins.split "[,;]" "a,b;c";
  splitWithGroup = builtins.split "([0-9])" "a1b2c";
  splitNoMatch = builtins.split "x" "abc";
  # 数字类要写成 POSIX 的 [[:digit:]]，\d 不是合法写法，见 regex_perl_fail.nix。
  posixClass = builtins.match "[[:digit:]]+" "42";
}
