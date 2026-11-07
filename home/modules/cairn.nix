# programs.cairn：把 cairn 做成 Home Manager 程序。
# 设置模块 cairn-settings 和第 16 章的 NixOS 模块用的是同一份，
# 这里只换宿主：配置写进 ~/.config，仓库建在 ~/.local/share，定时器是用户级 systemd。
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.programs.cairn;
  exe = lib.getExe cfg.package;
  conf = "${config.xdg.configHome}/cairn/cairn.conf";
  inherit (cfg.settings.cairn) repo;
in
{
  options.programs.cairn = {
    enable = lib.mkEnableOption "cairn, snapshot backups with hard links";

    package = lib.mkPackageOption pkgs "cairn" { };

    settings = mkOption {
      type = types.submodule {
        imports = [ ../../modules/cairn-settings.nix ];
        config.cairn.repo = lib.mkDefault "${config.home.homeDirectory}/.local/share/cairn/repo";
      };
      default = { };
      description = "Contents of cairn.conf, see `modules/cairn-settings.nix`.";
    };

    timer = {
      enable = lib.mkEnableOption "a systemd user timer that runs a snapshot";

      onCalendar = mkOption {
        type = types.str;
        default = "daily";
        description = "When the timer starts a snapshot, in `systemd.time(7)` syntax.";
        example = "03:00";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."cairn/cairn.conf".text = cfg.settings.cairn.configText;

    # 激活脚本排在 writeBoundary 之后，但 DAG 只保证这一条：linkGeneration
    # 也是“writeBoundary 之后”，在 demo 里它排在 cairnInit 后面（lab/ch18/hm_dag.nix）。
    # 所以首次激活时 cairn.conf 还没链接，cairn init 会先写一份模板，
    # 随后被 home-files 里的链接替换（nixos/tests/home.nix 记录了这一点）。
    home.activation.cairnInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${exe} -c ${conf} init ${repo}
    '';

    systemd.user = lib.mkIf cfg.timer.enable {
      services.cairn = {
        Unit.Description = "cairn snapshot of ${lib.concatStringsSep ", " cfg.settings.cairn.sources}";
        Service = {
          Type = "oneshot";
          ExecStart = "${exe} -c ${conf} snapshot";
          ExecStartPost = "${exe} -c ${conf} prune";
        };
      };

      timers.cairn = {
        Unit.Description = "cairn snapshot timer";
        Timer = {
          OnCalendar = cfg.timer.onCalendar;
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
