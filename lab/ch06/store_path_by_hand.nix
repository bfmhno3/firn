# Compute three text store paths by hand with Firn's textStorePath (sha256 of
# the content, fingerprint "text:<refs>:sha256:<hex>:/nix/store:<name>", sha256,
# XOR-fold to 20 bytes, nix32) and compare them with what builtins.toFile
# really returns. Any mismatch aborts evaluation, so the exit status is
# non-zero.
let
  lib = import ../../lib;

  dep = builtins.toFile "firn-dep" "I am a dependency.\n";
  withRef = "see ${dep} for details\n";

  cases = [
    {
      name = "firn-empty";
      content = "";
      references = [ ];
    }
    {
      name = "firn-hello.txt";
      content = "hello, firn\n";
      references = [ ];
    }
    {
      name = "firn-with-ref";
      content = withRef;
      references = [ dep ];
    }
  ];

  check =
    case:
    let
      computed = lib.textStorePath case;
      real = builtins.toFile case.name case.content;
    in
    {
      inherit (case) name;
      references = builtins.length case.references;
      inherit computed real;
      equal = computed == real;
    };

  results = map check cases;
in
if builtins.all (r: r.equal) results then
  results
else
  throw "store_path_by_hand: computed path differs from builtins.toFile"
