# Firn 自己的库入口，不依赖 nixpkgs。导出子集和扁平的常用函数。
let
  trivial = import ./trivial.nix;
  attrsets = import ./attrsets.nix;
  fixed-points = import ./fixed-points.nix;
in
{
  version = "0.1.0";
  inherit trivial attrsets fixed-points;
}
// trivial
// attrsets
// fixed-points
