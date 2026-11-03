# 把 data/chapters.toml 渲染成 README 里的章节表。
let
  pad2 = n: if n < 10 then "0${toString n}" else toString n;

  row = c: "| `ch${pad2 c.n}` | ${c.title} | `/posts/${c.stem}/` |";

  # 参数是 TOML 里的 chapters 数组；属性集按键排序，行序只能来自列表。
  renderChapterTable =
    chapters:
    builtins.concatStringsSep "\n" (
      [
        "| Chapter | Topic | Post |"
        "| --- | --- | --- |"
      ]
      ++ map row chapters
    )
    + "\n";
in
{
  inherit renderChapterTable;
}
