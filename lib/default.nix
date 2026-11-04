# Firn 自己的库入口，不依赖 nixpkgs。导出子集和扁平的常用函数。
let
  trivial = import ./trivial.nix;
  attrsets = import ./attrsets.nix;
  fixed-points = import ./fixed-points.nix;
  strings = import ./strings.nix;
  importers = import ./importers.nix;
  sources = import ./sources.nix;
  readme = import ./readme.nix;
  lists = import ./lists.nix;
  generators = import ./generators.nix;
  debug = import ./debug.nix;
  storePath = import ./store-path.nix;
in
{
  version = "0.1.0";
  inherit
    trivial
    attrsets
    fixed-points
    strings
    importers
    sources
    readme
    lists
    generators
    debug
    storePath
    ;
}
// trivial
// attrsets
// fixed-points
// strings
// importers
// sources
// readme
// lists
// generators
// debug
// storePath
