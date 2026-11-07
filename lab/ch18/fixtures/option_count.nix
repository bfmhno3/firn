# Counts the programs.* options of the demo evaluation with
# optionAttrSetToDocList (the list the manual is built from, hidden and
# internal options left out), and per program module.
let
  flake = builtins.getFlake (toString ../../..);
  inherit (flake.inputs.nixpkgs) lib;
  inherit (flake.homeConfigurations.demo) options;
  docs = lib.filter (o: o.visible && !o.internal) (lib.optionAttrSetToDocList options.programs);
  perProgram = lib.foldl' (
    acc: o:
    let
      name = builtins.elemAt (lib.splitString "." o.name) 1;
    in
    acc // { ${name} = (acc.${name} or 0) + 1; }
  ) { } docs;
  top = lib.take 5 (
    lib.sort (a: b: a.count > b.count || (a.count == b.count && a.name < b.name)) (
      lib.mapAttrsToList (name: count: { inherit name count; }) perProgram
    )
  );
in
{
  programsOptions = builtins.length docs;
  programsModules = builtins.length (builtins.attrNames perProgram);
  inherit top;
}
