# 字符串上下文的三种元素，以及哪些操作保留它、哪些操作丢掉它。
let
  pkgs = import (builtins.getEnv "FIRN_ROOT" + "/nix/pkgs.nix") { };
  hello = "${pkgs.hello}";
  keeps = s: builtins.hasContext s;
in
{
  kinds = {
    output = builtins.getContext "${pkgs.hello}";
    allOutputs = builtins.getContext pkgs.hello.drvPath;
    path = builtins.getContext "${./context_kinds.nix}";
    otherOutput = builtins.getContext "${pkgs.zlib.dev}";
  };
  keeps = {
    substring = keeps (builtins.substring 0 5 hello);
    replaceStrings = keeps (builtins.replaceStrings [ "hello" ] [ "bye" ] hello);
    concatStringsSep = keeps (builtins.concatStringsSep "," [ hello ]);
    toJSON = keeps (builtins.toJSON { p = hello; });
    baseNameOf = keeps (baseNameOf hello);
  };
  drops = {
    match = keeps (builtins.head (builtins.match "(.*)" hello));
    split = keeps (builtins.elemAt (builtins.split "-" hello) 0);
    hashString = keeps (builtins.hashString "sha256" hello);
    readFile = keeps (builtins.readFile (builtins.toFile "x" "abc"));
  };
}
