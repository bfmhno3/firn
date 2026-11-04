# A .drv file is itself a "text" store object: its path is textStorePath of the
# ATerm content, with the input derivations (here only busybox's .drv) as
# references. Compute the path of raw_hello's .drv by hand and compare it
# with the real one. A mismatch aborts evaluation, so the exit status is
# non-zero.
let
  lib = import ../../lib;
  inherit (import ./fixtures/prelude.nix) raw busybox;

  d = raw {
    name = "raw-hello";
    script = "echo 'hello from a raw derivation' > $out";
  };
  drv = builtins.unsafeDiscardStringContext d.drvPath;
  busyboxDrv = builtins.unsafeDiscardStringContext busybox.drvPath;

  computed = lib.textStorePath {
    name = "raw-hello.drv";
    content = builtins.readFile drv;
    references = [ busyboxDrv ];
  };
  result = {
    real = drv;
    inherit computed;
    equal = computed == drv;
  };
in
if result.equal then
  result
else
  throw "drv_path_by_hand: computed .drv path differs from the real one"
