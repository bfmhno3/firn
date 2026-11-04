# 最小的 stdenv：一个 mkDerivation，把 setup.sh 当作所有包共用的 builder。
{ busybox, system }:
{
  mkDerivation =
    {
      name,
      src ? null,
      buildInputs ? [ ],
      buildPhase ? "",
      installPhase ? "",
      ...
    }@args:
    derivation (
      removeAttrs args [ "src" ]
      // {
        inherit
          name
          system
          busybox
          buildInputs
          buildPhase
          installPhase
          ;
        builder = "${busybox}/bin/sh";
        args = [ ./setup.sh ];
      }
      // (if src == null then { } else { inherit src; })
    );
}
