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

  nameValuePair = name: value: { inherit name value; };

  # genAttrs [ "a" "b" ] f == { a = f "a"; b = f "b"; }
  genAttrs = names: f: builtins.listToAttrs (map (n: nameValuePair n (f n)) names);

  # 按键排序后把每个键值对映射成列表元素。
  mapAttrsToList = f: attrs: map (name: f name attrs.${name}) (builtins.attrNames attrs);

  filterAttrs =
    pred: set:
    builtins.listToAttrs (
      map (n: nameValuePair n set.${n}) (builtins.filter (n: pred n set.${n}) (builtins.attrNames set))
    );

  # f 返回 { name; value; }，可以改键；键冲突时先出现的（按键排序）胜出。
  mapAttrs' = f: set: builtins.listToAttrs (map (n: f n set.${n}) (builtins.attrNames set));
in
{
  inherit
    nameValuePair
    genAttrs
    mapAttrsToList
    filterAttrs
    mapAttrs'
    attrByPath
    hasAttrByPath
    setAttrByPath
    recursiveUpdate
    ;
}
