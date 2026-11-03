# 属性集工具，只依赖 builtins。
let
  # 沿 path 取值，任何一层缺失就返回 default。
  attrByPath =
    path: default: set:
    if path == [ ] then
      set
    else if builtins.isAttrs set && builtins.hasAttr (builtins.head path) set then
      attrByPath (builtins.tail path) default set.${builtins.head path}
    else
      default;

  hasAttrByPath =
    path: set:
    if path == [ ] then
      true
    else
      builtins.isAttrs set
      && builtins.hasAttr (builtins.head path) set
      && hasAttrByPath (builtins.tail path) set.${builtins.head path};

  # setAttrByPath [ "a" "b" ] 1 == { a = { b = 1; }; }
  setAttrByPath =
    path: value:
    if path == [ ] then
      value
    else
      { ${builtins.head path} = setAttrByPath (builtins.tail path) value; };

  # 与 `//` 不同：两边都是属性集的键会递归合并。
  recursiveUpdate =
    lhs: rhs:
    lhs
    // builtins.mapAttrs (
      name: value:
      if builtins.isAttrs value && builtins.isAttrs (lhs.${name} or null) then
        recursiveUpdate lhs.${name} value
      else
        value
    ) rhs;
in
{
  inherit
    attrByPath
    hasAttrByPath
    setAttrByPath
    recursiveUpdate
    ;
}
