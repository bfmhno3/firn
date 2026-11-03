# fromJSON (toJSON x) == x 对纯数据成立；路径会变成字符串，函数见 json_lambda_fail.nix。
let
  data = {
    n = 1;
    f = 1.5;
    s = "text";
    b = true;
    z = null;
    l = [
      1
      [ 2 ]
      { k = "v"; }
    ];
    nested.deep.er = [ ];
  };
  pathJson = builtins.toJSON ./fixtures/note.txt;
in
{
  roundtrip = builtins.fromJSON (builtins.toJSON data) == data;
  json = builtins.toJSON data;
  # 路径被复制进 store，JSON 里是带 store 上下文的字符串，不再是路径。
  pathJson = builtins.unsafeDiscardStringContext pathJson;
  pathJsonHasContext = builtins.hasContext pathJson;
  pathJsonIsString = builtins.typeOf pathJson;
  # 带 outPath 的集合被当成字符串，其他键丢失。
  outPathCollapses = builtins.toJSON {
    outPath = "/nix/store/x";
    other = 1;
  };
}
