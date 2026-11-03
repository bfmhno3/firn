# JSON 和 TOML：fromJSON、toJSON、fromTOML。TOML 日期不被支持，见 toml_datetime_fail.nix。
let
  lib = import ../../lib;
  chapters = (builtins.fromTOML (builtins.readFile ../../data/chapters.toml)).chapters;
in
{
  fromJson = builtins.fromJSON ''{"a": [1, 2.5, null, true], "b": {"c": "x"}}'';
  toJson = builtins.toJSON {
    b = 1;
    a = [
      "x"
      null
      2.5
    ];
  };
  # 整数和浮点在往返中保持各自的类型。
  intFloat = builtins.map builtins.typeOf (builtins.fromJSON "[1, 1.0]");
  chapterCount = builtins.length chapters;
  firstChapter = builtins.head chapters;
  lastChapter = builtins.elemAt chapters (builtins.length chapters - 1);
  sameAsLib = chapters == (lib.importTOML ../../data/chapters.toml).chapters;
  inlineToml = builtins.fromTOML ''
    name = "firn"
    [owner]
    login = "bfmhno3"
  '';
}
