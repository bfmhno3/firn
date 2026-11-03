# 把 Nix 值渲染成配置文件文本，只依赖 builtins。
let
  # 属性集按键排序，行序只能来自列表：
  # 参数可以是属性集（按键排序，和 nixpkgs 一致），
  # 也可以是 { name; value; } 的列表（保持列表顺序）。
  toPairs =
    input:
    if builtins.isList input then
      input
    else
      builtins.attrValues (builtins.mapAttrs (name: value: { inherit name value; }) input);

  renderScalar =
    v:
    if builtins.isBool v then
      (if v then "true" else "false")
    else if builtins.isString v then
      v
    else
      toString v;

  # 列表值展开成每个元素一行 `key = value`。
  toKeyValue =
    {
      sep ? " = ",
    }:
    input:
    builtins.concatStringsSep "" (
      map (
        pair:
        let
          values = if builtins.isList pair.value then pair.value else [ pair.value ];
        in
        builtins.concatStringsSep "" (map (v: "${pair.name}${sep}${renderScalar v}\n") values)
      ) (toPairs input)
    );

  # 外层是节名，内层交给 toKeyValue；节之间空一行。
  toINI =
    {
      sep ? " = ",
    }:
    input:
    builtins.concatStringsSep "\n" (
      map (section: "[${section.name}]\n${toKeyValue { inherit sep; } section.value}") (toPairs input)
    );
in
{
  inherit toKeyValue toINI;
}
