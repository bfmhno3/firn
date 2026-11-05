# import nixpkgs { config; overlays; }：config 在 import 时决定哪些包能求值。
# unrar 的许可证是 unfree，config 默认拒绝；allowUnfree = true 放行全部，
# allowUnfreePredicate 只放行点名的包。拒绝发生在取 drvPath 时（取 name 不检查），
# builtins.tryEval 接住 throw，只打印是否求值成功。
let
  nixpkgs = (import ../../nix/pins.nix).nixpkgs;
  system = builtins.currentSystem;
  withConfig =
    config:
    import nixpkgs {
      inherit system config;
    };
  evaluates = pkg: (builtins.tryEval pkg.drvPath).success;
  plain = withConfig { };
  onlyUnrar = withConfig {
    allowUnfreePredicate = pkg: (plain.lib.getName pkg) == "unrar";
  };
in
{
  unrar_meta_unfree = plain.unrar.meta.unfree;
  config_empty = evaluates plain.unrar;
  allowUnfree_true = evaluates (withConfig { allowUnfree = true; }).unrar;
  predicate_unrar_ok = evaluates onlyUnrar.unrar;
  predicate_vscode_rejected = !(evaluates onlyUnrar.vscode);
  # 纯自由软件不受影响。
  hello_with_empty_config = evaluates plain.hello;
}
