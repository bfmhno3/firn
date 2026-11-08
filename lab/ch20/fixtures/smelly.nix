# BAD: deliberately smelly Nix, input for lint_tools.sh. It parses and is
# formatted; statix and deadnix each find problems in it. The comment above
# each attribute names the statix lint that reports it.
{
  pkgs,
  unusedArg,
}:
let
  unusedBinding = 1;
  greeting = "hello";
in
{
  # manual_inherit
  greeting = greeting;
  # repeated_keys
  a.b = 1;
  a.c = 2;
  a.d = 3;
  # eta_reduction
  show = x: toString x;
  # useless_parens
  parens = (1 + 2);
  # empty_pattern
  noArgs = { ... }: 1;
  # empty_let_in
  emptyLet =
    let
    in
    1;
  # empty_list_concat
  concat = [ ] ++ [ 1 ];
  inherit (pkgs) hello;
}
