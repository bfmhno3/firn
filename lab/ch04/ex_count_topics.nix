# 练习参考答案：统计 data/chapters.toml 里所有主题的出现次数。
let
  lib = import ../../lib;
  chapters = (lib.importTOML ../../data/chapters.toml).chapters;
  allTopics = builtins.concatLists (map (c: c.topics) chapters);
  counts = builtins.mapAttrs (_: builtins.length) (builtins.groupBy (t: t) allTopics);
in
{
  chapters = builtins.length chapters;
  topicsTotal = builtins.length allTopics;
  topicsDistinct = builtins.length (builtins.attrNames counts);
  repeated = builtins.listToAttrs (
    builtins.filter (kv: kv.value > 1) (
      map (name: {
        inherit name;
        value = counts.${name};
      }) (builtins.attrNames counts)
    )
  );
}
