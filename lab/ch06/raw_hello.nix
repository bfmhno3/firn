# The smallest derivation Firn has: a name and a one-line sh script, built by
# the static busybox, no stdenv. Evaluating it only instantiates (writes the
# .drv, builds nothing); `nix eval` prints «derivation <drvPath>». build_raw.sh
# builds this file and prints outPath next to drvPath.
let
  inherit (import ./fixtures/prelude.nix) raw;
in
raw {
  name = "raw-hello";
  script = "echo 'hello from a raw derivation' > $out";
}
