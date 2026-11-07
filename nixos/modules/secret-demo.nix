# services.firn-secret-demo：演示 sops-nix 解出来的密文怎么交给服务。
# 密文在激活时解密到 /run/secrets（tmpfs），服务用 LoadCredential 拿到一份
# 只有它自己能读的副本，只把 sha256 打到日志里，明文不出现在 store 或日志里。
# 需要同时导入 sops-nix 的模块，并声明 sops.secrets."firn/token"。
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.firn-secret-demo;
  show = pkgs.writeShellScript "firn-secret-demo" ''
    hash="$(${pkgs.coreutils}/bin/sha256sum < "$CREDENTIALS_DIRECTORY/token")"
    echo "firn-secret-demo: sha256=''${hash%% *}"
  '';
in
{
  options.services.firn-secret-demo.enable = lib.mkEnableOption "the secret demo service";

  config = lib.mkIf cfg.enable {
    systemd.services.firn-secret-demo = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        DynamicUser = true;
        LoadCredential = "token:${config.sops.secrets."firn/token".path}";
        ExecStart = show;
      };
    };
  };
}
