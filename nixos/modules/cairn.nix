# services.cairn：把 cairn 做成 NixOS 服务。
# 设置模块 cairn-settings（第 15 章）原样放进 settings 子模块，
# 渲染出的配置文本写进 /etc/cairn/cairn.conf，systemd 定时器按 onCalendar 触发快照。
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.services.cairn;
  exe = lib.getExe cfg.package;
  conf = "/etc/cairn/cairn.conf";
  inherit (cfg.settings.cairn) repo;
in
{
  options.services.cairn = {
    enable = lib.mkEnableOption "periodic cairn snapshots";

    package = lib.mkPackageOption pkgs "cairn" { };

    settings = mkOption {
      type = types.submodule {
        imports = [ ../../modules/cairn-settings.nix ];
        config.cairn.repo = lib.mkDefault "/var/lib/cairn/repo";
      };
      default = { };
      description = "Contents of cairn.conf, see `modules/cairn-settings.nix`.";
    };

    onCalendar = mkOption {
      type = types.str;
      default = "daily";
      description = "When the timer starts a snapshot, in `systemd.time(7)` syntax.";
      example = "03:00";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.cairn = {
      isSystemUser = true;
      group = "cairn";
      description = "cairn snapshot service";
    };
    users.groups.cairn = { };

    environment.etc."cairn/cairn.conf".text = cfg.settings.cairn.configText;
    environment.systemPackages = [ cfg.package ];

    systemd = {
      # ReadWritePaths 在服务启动前就要挂载仓库目录，而 init 在 ExecStartPre
      # 里才创建它：没有这条规则，首次启动会因为目录不存在而 226/NAMESPACE。
      tmpfiles.rules = [ "d ${repo} 0750 cairn cairn -" ];

      services.cairn = {
        description = "cairn snapshot of ${lib.concatStringsSep ", " cfg.settings.cairn.sources}";
        serviceConfig = {
          Type = "oneshot";
          User = "cairn";
          Group = "cairn";
          StateDirectory = "cairn";
          ExecStartPre = "${exe} -c ${conf} init ${repo}";
          ExecStart = "${exe} -c ${conf} snapshot";
          ExecStartPost = "${exe} -c ${conf} prune";

          # 只读整个文件系统，仓库目录除外。
          ProtectSystem = "strict";
          ReadWritePaths = [ repo ];
          ProtectHome = "read-only";
          PrivateTmp = true;
          NoNewPrivileges = true;
        };
      };

      timers.cairn = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.onCalendar;
          Persistent = true;
        };
      };
    };
  };
}
