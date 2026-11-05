# Out paths and contents of the trivial builders: writeText, writeTextFile,
# runCommand, symlinkJoin and linkFarm. Contents are read back with
# builtins.readFile, so the files are built during evaluation (IFD).
let
  pkgs = import ../../nix/pkgs.nix { };
  text = pkgs.writeText "greeting.txt" "hello\n";
  file = pkgs.writeTextFile {
    name = "tool";
    text = "#!/bin/sh\necho tool\n";
    destination = "/bin/tool";
    executable = true;
  };
  run = pkgs.runCommand "upper" { } ''
    echo hello | tr a-z A-Z > $out
  '';
  docs = pkgs.writeTextDir "share/doc/readme.txt" "docs\n";
  join = pkgs.symlinkJoin {
    name = "joined";
    paths = [
      file
      docs
    ];
  };
  farm = pkgs.linkFarm "farm" {
    "a.txt" = text;
    "bin/tool" = "${file}/bin/tool";
  };
in
{
  writeText = {
    outPath = "${text}";
    content = builtins.readFile text;
  };
  writeTextFile = {
    outPath = "${file}";
    content = builtins.readFile "${file}/bin/tool";
  };
  runCommand = {
    outPath = "${run}";
    content = builtins.readFile run;
  };
  symlinkJoin = {
    outPath = "${join}";
    topLevel = builtins.attrNames (builtins.readDir join);
    binEntries = builtins.attrNames (builtins.readDir "${join}/bin");
  };
  linkFarm = {
    outPath = "${farm}";
    entries = builtins.attrNames (builtins.readDir farm);
  };
}
