# 渲染 README 的章节表；README 里两个标记之间的内容必须等于
# `nix eval --raw --file lab/ch04/render_table.nix` 的输出。
let
  lib = import ../../lib;
in
lib.renderChapterTable (lib.importTOML ../../data/chapters.toml).chapters
