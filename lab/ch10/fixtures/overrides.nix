# firn-hello 的几种改法，供 override_kinds.sh 取 out path 和 name。
# 只求值，不构建 rebuilt：它把问候语改成 Moin，而 installCheckPhase 期望 Hello，
# 所以真去构建会失败；这里只用它说明 env 变了 out path 就变。
let
  pkgs = import ../../../nix/pkgs.nix { };
  base = pkgs.firn-hello;
in
{
  inherit base;
  # 改 package.nix 的参数：drv 换，name 不变。
  overridden = base.override { greeting = "Hallo"; };
  # 改 mkDerivation 的属性：version 变，mkDerivation 由 pname 和 version 算出的 name 跟着变。
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
  # 不推荐（手册称 discouraged）：直接改最终传给 derivation 的参数，name 已经算好，不会跟着变。
  legacy = pkgs.lib.overrideDerivation base (_: {
    version = "0.1.1";
  });
}
