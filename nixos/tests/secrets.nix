# 两个节点对比：sops 节点用 sops-nix 在激活时解密，naive 节点把令牌直接写进
# environment.etc（于是进了 store）。测试数出每个节点系统闭包里含明文的
# store 路径，并以 `firn: <key> <value>` 打印。
{ pkgs, sopsModule }:
pkgs.testers.runNixOSTest {
  name = "secrets";

  nodes.sops = {
    imports = [
      sopsModule
      ../modules/secret-demo.nix
    ];

    sops = {
      defaultSopsFile = ./secrets/secrets.yaml;
      age.keyFile = "/run/age-key.txt";
      secrets."firn/token" = { };
    };

    # 照 sops-nix 自己的 NixOS 测试：私钥要在 sops 安装密文之前就位，
    # 所以挂一段早于 setupSecrets 的激活脚本。这把私钥是测试专用、公开的。
    system.activationScripts.firnAgeKey = {
      text = ''
        install -m 400 ${./secrets/age-key.txt} /run/age-key.txt
      '';
    };
    system.activationScripts.setupSecrets.deps = [ "firnAgeKey" ];

    services.firn-secret-demo.enable = true;
  };

  nodes.naive = {
    environment.etc."firn-token".text = "correct-horse-battery-staple";
  };

  testScript = ''
    import hashlib

    token = "correct-horse-battery-staple"


    def report(key, value):
        print(f"firn: {key} {value}")


    def plaintext_paths(node):
        # 只看本节点的系统闭包：测试虚拟机里 /nix/store 是宿主 store 的只读视图，
        # 整个扫一遍会扫到宿主上无关的路径（包括这份测试脚本本身）。
        out = node.succeed(
            "nix-store -qR /run/current-system"
            f" | xargs grep -rlF {token} || true"
        )
        return out.split()


    start_all()
    sops.wait_for_unit("multi-user.target")
    naive.wait_for_unit("multi-user.target")

    sops.wait_for_unit("firn-secret-demo.service")
    mode = sops.succeed("stat -c %a /run/secrets/firn/token").strip()
    assert mode == "400", mode
    report("sops_secret_mode", mode)
    report("sops_secret_fs", sops.succeed("stat -L -f -c %T /run/secrets").strip())

    expected = hashlib.sha256(token.encode()).hexdigest()
    journal = sops.succeed("journalctl -u firn-secret-demo.service --no-pager")
    assert f"firn-secret-demo: sha256={expected}" in journal, journal
    report("sops_journal", f"sha256={expected}")

    sops_paths = plaintext_paths(sops)
    assert sops_paths == [], sops_paths
    report("sops_plaintext_store_paths", len(sops_paths))

    naive_paths = plaintext_paths(naive)
    assert len(naive_paths) >= 1, naive_paths
    report("naive_plaintext_store_paths", len(naive_paths))
    store_mode = naive.succeed("stat -L -c %a /etc/firn-token").strip()
    report("naive_store_file_mode", store_mode)
  '';
}
