# firn-hello 的几种改法，供 override_kinds.sh 取 out path 和 name。
let
  pkgs = import ../../../nix/pkgs.nix { };
  base = pkgs.firn-hello;
in
{
  inherit base;
  # 改 package.nix 的参数：drv 换，name 不变。
  overridden = base.override { greeting = "Hallo"; };
  # 改 mkDerivation 的属性：version 变，name 跟着 finalAttrs 变。
  bumped = base.overrideAttrs (_: {
    version = "0.1.1";
    __intentionallyOverridingVersion = true;
  });
  # 同样的改法，不加 __intentionallyOverridingVersion：求值时 nixpkgs 会警告只改了 version。
  bumpedNoisy = base.overrideAttrs (_: {
    version = "0.1.1";
  });
  # 在 old 的基础上追加：env 是属性集，这里整体替换。
  rebuilt = base.overrideAttrs (old: {
    env = old.env // {
      NIX_CFLAGS_COMPILE = "-DFIRN_GREETING=\"Moin\"";
    };
  });
  # 已弃用：直接改最终传给 derivation 的参数，看不到 finalAttrs。
  legacy = pkgs.lib.overrideDerivation base (_: {
    version = "0.1.1";
  });
}
