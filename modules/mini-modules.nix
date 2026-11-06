# 一个够用的模块系统：lib.evalModules 的骨架，只依赖 builtins。
#
# 模块是属性集，或者 { config, ... }: 的函数，返回
# { imports ? [ ], options ? { }, config ? { } }。
# 类型只有 str、int、bool、listOf、attrsOf；优先级和 nixpkgs 一致：
# mkDefault 1000，普通定义 100，mkForce 50，选项默认值 1500。
# 同优先级：列表拼接，属性集按名合并，标量必须相等。
# 故意没做的事（lib/modules.nix 做了）：mkMerge、mkOrder、submodule、
# 未声明选项的报错、_module.args、定义位置。
let
  isOption = v: builtins.isAttrs v && (v._type or "") == "option";
  isIf = v: builtins.isAttrs v && (v._type or "") == "if";
  isOverride = v: builtins.isAttrs v && (v._type or "") == "override";

  mkOption = args: args // { _type = "option"; };
  mkOverride = priority: content: {
    _type = "override";
    inherit priority content;
  };
  mkDefault = mkOverride 1000;
  mkForce = mkOverride 50;
  mkIf = condition: content: {
    _type = "if";
    inherit condition content;
  };

  # 选项的默认值是优先级 1500 的定义，任何人写的值都能盖过它。
  defaultPriority = 1500;
  plainPriority = 100;

  showLoc = builtins.concatStringsSep ".";

  show =
    v:
    let
      r = builtins.tryEval (builtins.toJSON v);
    in
    if r.success then r.value else "<${builtins.typeOf v}>";

  conflict = loc: throw "firn: option '${showLoc loc}' has conflicting definitions";

  # 标量：所有定义必须相等。
  mergeEqual =
    loc: defs:
    let
      first = builtins.head defs;
    in
    if builtins.all (d: d == first) defs then first else conflict loc;

  scalar = name: check: {
    inherit name check;
    merge = mergeEqual;
  };

  types = {
    str = scalar "str" builtins.isString;
    int = scalar "int" builtins.isInt;
    bool = scalar "bool" builtins.isBool;

    listOf = elem: {
      name = "listOf ${elem.name}";
      check = v: builtins.isList v && builtins.all elem.check v;
      merge = _loc: defs: builtins.concatLists defs;
    };

    attrsOf = elem: {
      name = "attrsOf ${elem.name}";
      check = v: builtins.isAttrs v && builtins.all elem.check (builtins.attrValues v);
      merge =
        loc: defs:
        builtins.mapAttrs (name: values: elem.merge (loc ++ [ name ]) values) (
          builtins.zipAttrsWith (_name: values: values) defs
        );
    };
  };

  # 把一个定义拆成 { active, priority, value }；mkIf 的条件只在 active 被用到时才求值。
  resolve =
    def:
    if isIf def then
      let
        inner = resolve def.content;
      in
      inner // { active = def.condition && inner.active; }
    else if isOverride def then
      (resolve def.content) // { inherit (def) priority; }
    else
      {
        active = true;
        priority = plainPriority;
        value = def;
      };

  # 在一个模块的 config 里找 path 处的定义。mkIf 往下推：
  # 只看 content 的属性名，不碰条件，这就是 mkIf 不会递归的原因。
  select =
    path: cfg:
    if path == [ ] then
      [ cfg ]
    else if isIf cfg then
      map (mkIf cfg.condition) (select path cfg.content)
    else if builtins.isAttrs cfg && cfg ? ${builtins.head path} then
      select (builtins.tail path) cfg.${builtins.head path}
    else
      [ ];

  # 合并各模块的 options；同一个选项声明两次是错误。
  mergeDeclarations =
    loc: trees:
    builtins.zipAttrsWith (
      name: vs:
      if builtins.length vs == 1 then
        builtins.head vs
      else if builtins.any isOption vs then
        throw "firn: option '${showLoc (loc ++ [ name ])}' is declared more than once"
      else
        mergeDeclarations (loc ++ [ name ]) vs
    ) trees;

  evalMini =
    { modules }:
    let
      # 模块函数拿到的 config 就是最终的 config：定点。
      applyModule =
        m:
        if builtins.isFunction m then
          m { inherit config; }
        else if builtins.isPath m then
          applyModule (import m)
        else
          m;

      collect =
        ms:
        builtins.concatMap (
          raw:
          let
            m = applyModule raw;
          in
          collect (m.imports or [ ]) ++ [ m ]
        ) ms;

      all = collect modules;
      options = mergeDeclarations [ ] (map (m: m.options or { }) all);

      evalOption =
        loc: opt:
        let
          fromModules = builtins.concatMap (m: select loc (m.config or { })) all;
          fromDefault = if opt ? default then [ (mkOverride defaultPriority opt.default) ] else [ ];
          resolved = builtins.filter (d: d.active) (map resolve (fromModules ++ fromDefault));
          best = builtins.foldl' (a: d: if d.priority < a then d.priority else a) 1000000 resolved;
          winners = map (d: d.value) (builtins.filter (d: d.priority == best) resolved);
          bad = builtins.filter (v: !opt.type.check v) winners;
        in
        if resolved == [ ] then
          throw "firn: option '${showLoc loc}' is used but not defined"
        else if bad != [ ] then
          throw "firn: option '${showLoc loc}' has type ${opt.type.name} but got ${show (builtins.head bad)}"
        else
          opt.type.merge loc winners;

      build =
        loc: tree:
        builtins.mapAttrs (
          name: v: if isOption v then evalOption (loc ++ [ name ]) v else build (loc ++ [ name ]) v
        ) tree;

      config = build [ ] options;
    in
    {
      inherit config options;
    };
in
{
  inherit
    evalMini
    mkOption
    mkOverride
    mkDefault
    mkForce
    mkIf
    types
    ;
}
