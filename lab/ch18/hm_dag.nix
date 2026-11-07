# The order in which the demo's activation script runs its entries. Every
# entry of config.home.activation is a node of a DAG (`after`/`before` edges);
# Home Manager's topoSort turns it into the sequence of the activate script.
# Note where cairnInit (after writeBoundary only) lands relative to
# linkGeneration, which is also "after writeBoundary".
let
  flake = builtins.getFlake (toString ../..);
  inherit (flake.inputs.home-manager.lib.hm) dag;
  inherit (flake.inputs.nixpkgs.lib.lists) findFirstIndex;
  inherit (flake.homeConfigurations.demo.config.home) activation;
  order = map (entry: entry.name) (dag.topoSort activation).result;
  position = name: findFirstIndex (entry: entry == name) null order;
in
{
  inherit order;
  edges = builtins.mapAttrs (_: entry: { inherit (entry) before after; }) activation;
  cairnInitBeforeLinkGeneration = position "cairnInit" < position "linkGeneration";
}
