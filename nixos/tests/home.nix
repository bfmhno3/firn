# Home Manager 作为 NixOS 模块的虚拟机测试：用户 alice 开了 linger，
# 她的 programs.cairn 带一个用户级定时器。测试检查 cairn.conf 是指进 store 的
# 符号链接、定时器在用户 systemd 里、激活脚本建了仓库，
# 并把测得的数值以 `firn: <key> <value>` 打印。
{
  pkgs,
  homeManagerModule,
  cairnHomeModule,
  overlay,
}:
pkgs.testers.runNixOSTest {
  name = "home";

  # 系统自己要加 overlay（下面），所以关掉只读 pkgs。
  node.pkgsReadOnly = false;

  nodes.machine =
    { ... }:
    {
      imports = [ homeManagerModule ];
      nixpkgs.overlays = [ overlay ];

      users.users.alice = {
        isNormalUser = true;
        linger = true;
      };

      home-manager = {
        # 用系统的 pkgs 求值用户配置，不再为每个用户 import 一遍 nixpkgs。
        useGlobalPkgs = true;
        users.alice =
          { config, ... }:
          {
            imports = [ cairnHomeModule ];
            home.stateVersion = "26.05";
            # 作为 NixOS 模块时 programs.home-manager.enable 不装命令行工具，
            # 要自己把它的包放进用户环境。
            home.packages = [ config.programs.home-manager.package ];
            programs = {
              cairn = {
                enable = true;
                settings.cairn.sources = [ "/home/alice/docs" ];
                timer.enable = true;
              };
            };
          };
      };
    };

  testScript =
    { nodes, ... }:
    ''
      import re


      def report(key, value):
          print(f"firn: {key} {value}")


      def as_alice(cmd):
          return machine.succeed(f"runuser -u alice -- {cmd}")


      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("home-manager-alice.service")
      machine.wait_for_unit("user@1000.service")

      conf = "/home/alice/.config/cairn/cairn.conf"
      machine.succeed(f"test -L {conf}")
      target = machine.succeed(f"readlink {conf}").strip()
      assert target.startswith("/nix/store/"), target
      report("conf_symlink", "into /nix/store")
      resolved = machine.succeed(f"readlink -f {conf}").strip()
      report("conf_target", re.sub(r"^/nix/store/[a-z0-9]{32}-", "", resolved))
      machine.succeed(f"grep -q '^source = /home/alice/docs$' {conf}")

      machine.succeed("test -f /home/alice/.local/share/cairn/repo/cairn.repo")
      report("repo_marker", "cairn.repo")
      # cairn init 在配置文件不存在时会写一份模板。激活里 cairnInit 排在
      # linkGeneration 之前，看看它有没有这么做。
      journal = machine.succeed("journalctl -u home-manager-alice.service --no-pager")
      report("init_wrote_template", "wrote /home/alice/.config/cairn/cairn.conf" in journal)

      timers = machine.succeed("systemctl --user -M alice@ list-timers --all")
      assert "cairn" in timers, timers
      report("user_timer", "cairn.timer")
      report("linger_file", machine.succeed("ls /var/lib/systemd/linger").strip())

      # 作为 NixOS 模块，激活由 home-manager-alice.service 完成，不登记
      # home-manager 的 profile，所以 generations 是空的（退出码 1）。
      hm = "/home/alice/.nix-profile/bin/home-manager"
      status, out = machine.execute(f"runuser -u alice -- {hm} generations")
      report("hm_generations_nixos_module", f"exit {status}, {len(out.splitlines())} lines")

      # home-manager switch 在独立模式下做的事：把激活包登记成 home-manager
      # profile 的一代。登记之后 generations 才有第一行。
      package = "${nodes.machine.home-manager.users.alice.home.activationPackage}"
      profile = "/home/alice/.local/state/nix/profiles/home-manager"
      as_alice(f"nix-env --profile {profile} --set {package}")
      generations = as_alice(f"{hm} generations")
      line = re.sub(r"^.*: id", "id", generations.strip().splitlines()[0])
      report("hm_generations", re.sub(r"/nix/store/[a-z0-9]{32}-", "", line))
    '';
}
