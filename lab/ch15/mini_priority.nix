# mini 的优先级：数字小的赢。mkDefault 1000，普通定义 100，mkForce 50，
# 选项自己的 default 是 1500。每个例子是独立的一次求值。
let
  mini = import ../../modules/mini-modules.nix;
  inherit (mini)
    evalMini
    mkOption
    mkDefault
    mkForce
    types
    ;

  declare = {
    options.level = mkOption {
      type = types.str;
      default = "option default (1500)";
    };
  };

  levelOf =
    defs:
    (evalMini {
      modules = [ declare ] ++ map (value: { config.level = value; }) defs;
    }).config.level;
in
{
  onlyOptionDefault = levelOf [ ];
  mkDefaultBeatsOptionDefault = levelOf [ (mkDefault "mkDefault (1000)") ];
  plainBeatsMkDefault = levelOf [
    (mkDefault "mkDefault (1000)")
    "plain (100)"
  ];
  mkForceBeatsPlain = levelOf [
    "plain (100)"
    (mkForce "mkForce (50)")
    (mkDefault "mkDefault (1000)")
  ];
  # 顺序无关：定义列表反过来结果一样。
  orderDoesNotMatter = levelOf [
    (mkDefault "mkDefault (1000)")
    (mkForce "mkForce (50)")
    "plain (100)"
  ];
}
