# 不动点：`fix`、overlay 风格的 `extends` 和可扩展的属性集。
# 和 nixpkgs 的 lib/fixed-points.nix 同一个思路，去掉了文档和别名。
rec {
  # fix f = f (fix f)，但让结果指向自己，这样 self 只求值一次。
  fix =
    f:
    let
      x = f x;
    in
    x;

  # 把 overlay `f`（final: prev: 增量）套到 `rattrs`（self: 属性集）上。
  extends =
    f: rattrs: self:
    let
      super = rattrs self;
    in
    super // f self super;

  # 组合两个 overlay：g 看到的 prev 已经包含 f 的结果。
  composeExtensions =
    f: g: final: prev:
    let
      fApplied = f final prev;
      prev' = prev // fApplied;
    in
    fApplied // g final prev';

  # 从左到右组合一串 overlay；空列表是什么都不改的 overlay。
  composeManyExtensions = builtins.foldl' composeExtensions (_: _: { });

  # 返回的属性集带 `.extend overlay`，得到一个新的可扩展属性集。
  makeExtensible =
    rattrs:
    fix (
      self:
      rattrs self
      // {
        extend = f: makeExtensible (extends f rattrs);
      }
    );
}
