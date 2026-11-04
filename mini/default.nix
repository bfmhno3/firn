# mini 包集：一个不动点，包之间靠 callPackage 从 self 里按名字取依赖。
{
  busybox,
  system,
  lib ? import ../lib,
}:
lib.makeExtensible (self: {
  inherit busybox;

  callPackage =
    fn: args:
    let
      f = if builtins.isFunction fn then fn else import fn;
    in
    f (builtins.intersectAttrs (builtins.functionArgs f) self // args);

  inherit (import ./stdenv { inherit busybox system; }) mkDerivation;
  fetchurl = import <nix/fetchurl.nix>;

  greeting = self.callPackage ./pkgs/greeting.nix { };
  hello = self.callPackage ./pkgs/hello.nix { };
  wordfreq = self.callPackage ./pkgs/wordfreq.nix { };
  cairn-src = self.callPackage ./pkgs/cairn-src.nix { };
  site = self.callPackage ./pkgs/site.nix { };
})
