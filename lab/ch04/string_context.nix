# 字符串上下文：插值一个 derivation 得到的字符串带着“依赖了谁”的记录。
let
  pkgs = import ../../nix/pkgs.nix { };
  s = "${pkgs.hello}";
  plain = "just text";
  discarded = builtins.unsafeDiscardStringContext s;
in
{
  helloPath = s;
  hasContext = builtins.hasContext s;
  plainHasContext = builtins.hasContext plain;
  context = builtins.getContext s;
  # 拼接会合并上下文。
  concatenated = builtins.attrNames (builtins.getContext "${s} and ${pkgs.jq}");
  discardedHasContext = builtins.hasContext discarded;
  # 字符串比较不看上下文，所以丢掉之后仍然相等。
  samePath = discarded == s;
}
