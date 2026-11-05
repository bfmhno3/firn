# 两个只差一个写法的小包：一个用 rec，一个用 finalAttrs。
# overrideAttrs 改 version 后，只有 finalAttrs 那个的 TAG 跟着变。
let
  pkgs = import ../../../nix/pkgs.nix { };
  withRec = pkgs.stdenv.mkDerivation rec {
    pname = "tagged-rec";
    version = "1";
    dontUnpack = true;
    # BAD: version 在 rec 里已经定死，overrideAttrs 改不到这里
    TAG = "v${version}";
    installPhase = "echo \"$TAG\" > $out";
  };
  withFinal = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "tagged-final";
    version = "1";
    dontUnpack = true;
    TAG = "v${finalAttrs.version}";
    installPhase = "echo \"$TAG\" > $out";
  });
  bump = _: { version = "2"; };
in
{
  rec_name = (withRec.overrideAttrs bump).name;
  rec_TAG = (withRec.overrideAttrs bump).TAG;
  final_name = (withFinal.overrideAttrs bump).name;
  final_TAG = (withFinal.overrideAttrs bump).TAG;
}
