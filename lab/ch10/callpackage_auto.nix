# callPackage 自动供参：functionArgs 列出 package.nix 要的参数（值表示有没有
# 默认值），callPackage 用 intersectAttrs 从 pkgs 里挑出同名项，再合并显式参数。
# 这里手工重做一遍，核对结果与 pkgs.firn-hello 是同一个 drv；
# 另外演示显式参数覆盖自动参数，以及 override 函数从哪里来。
let
  pkgs = import ../../nix/pkgs.nix { };
  f = import ../../pkgs/firn-hello/package.nix;
  wanted = builtins.functionArgs f;
  auto = builtins.intersectAttrs wanted pkgs;
  byHand = f auto;
  viaCallPackage = pkgs.callPackage f { };
  hallo = pkgs.callPackage f { greeting = "Hallo"; };
in
{
  functionArgs = wanted;
  # 自动供给的名字：greeting 不在 pkgs 里，所以没有被供给，走默认值。
  suppliedNames = builtins.attrNames auto;
  missingFromPkgs = builtins.filter (n: !(auto ? ${n})) (builtins.attrNames wanted);
  sameDrvAsByHand = byHand.drvPath == viaCallPackage.drvPath;
  sameDrvAsOverlay = viaCallPackage.drvPath == pkgs.firn-hello.drvPath;
  # 显式参数覆盖自动参数，且换了 drv。
  explicitArgChangesDrv = hallo.drvPath != viaCallPackage.drvPath;
  # callPackage 的结果带 override（makeOverridable 加的），手工调用 f 的没有。
  callPackageHasOverride = viaCallPackage ? override;
  byHandHasOverride = byHand ? override;
}
