# 用 generators 渲染 cairn 的配置文本和一份 INI。
# toKeyValue 的参数用 { name; value; } 列表，行序就是列表顺序；
# 属性集会按键排序，repo 会排到 source 后面，所以不能用来写 cairn.conf。
let
  lib = import ../../lib;
  pair = lib.nameValuePair;

  cairnConf = lib.toKeyValue { } [
    (pair "repo" "/var/lib/cairn/repo")
    (pair "source" [
      "/srv/data"
      "/etc"
    ])
    (pair "exclude" [ "*.tmp" ])
    (pair "keep_last" 5)
    (pair "keep_daily" 7)
    (pair "keep_weekly" 4)
  ];

  ini = lib.toINI { } [
    (pair "service" {
      enabled = true;
      port = 8080;
    })
    (pair "paths" { root = "/srv"; })
  ];

  expectedConf = "repo = /var/lib/cairn/repo\nsource = /srv/data\nsource = /etc\nexclude = *.tmp\nkeep_last = 5\nkeep_daily = 7\nkeep_weekly = 4\n";
in
if cairnConf == expectedConf then
  {
    cairnConf = lib.splitString "\n" cairnConf;
    ini = lib.splitString "\n" ini;
    sortedAttrsetOrder = lib.splitString "\n" (
      lib.toKeyValue { } {
        repo = "/r";
        keep_last = 5;
        source = [ "/a" ];
      }
    );
  }
else
  throw "cairn.conf text differs from the expected order"
