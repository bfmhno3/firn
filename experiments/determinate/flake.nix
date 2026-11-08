# 第 19 章：Determinate NixOS 模块放进 runNixOSTest。
# 一台虚拟机装上 determinate.nixosModules.default，测试读出它的 nix 版本、
# 配置文件、determinate-nixd 单元，再量惰性树和并行求值。
# 这个实验不属于 Firn 主 flake：主 flake 没有 Determinate 输入。
{
  description = "firn chapter 19: Determinate Nix in a NixOS VM test";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/56c02bc00adcf003215cc4bd996d6efaf4cff188";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  };

  nixConfig = {
    extra-substituters = [ "https://install.determinate.systems" ];
    extra-trusted-public-keys = [
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
    ];
  };

  outputs =
    { nixpkgs, determinate, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      # 一个能求值的最小 NixOS：configuration = { } 会因为缺根文件系统和引导
      # 加载器的断言失败。
      minimalOs = pkgs.writeText "minimal-os.nix" ''
        (import <nixpkgs/nixos> {
          configuration = {
            boot.loader.grub.enable = false;
            fileSystems."/" = {
              device = "none";
              fsType = "tmpfs";
            };
            system.stateVersion = "26.05";
          };
        }).config.system.build.toplevel.drvPath
      '';
    in
    {
      checks.x86_64-linux.determinate-vm = pkgs.testers.runNixOSTest {
        name = "determinate";

        nodes.machine =
          { pkgs, ... }:
          {
            imports = [ determinate.nixosModules.default ];

            virtualisation = {
              diskSize = 8192;
              memorySize = 4096;
              cores = 4;
              # 虚拟机里没有网络，<nixpkgs/nixos> 要的源码得自带。
              additionalPaths = [ pkgs.path ];
            };
            nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
          };

        testScript = ''
          import statistics

          RUNS = 5


          def report(key, value):
              print(f"firn: {key} {value}")


          def wall_ms(cmd):
              """Run cmd inside the VM and return its wall time in ms."""
              out = machine.succeed(
                  f"s=$(date +%s%3N); {cmd} >/dev/null; "
                  "e=$(date +%s%3N); echo $((e - s))"
              )
              return int(out.strip().splitlines()[-1])


          def store_mb():
              return int(machine.succeed("du -sm /nix/store | cut -f1"))


          def key_lines(path):
              text = machine.succeed(f"grep -v '^#' {path} | grep .")
              for line in text.splitlines():
                  yield line if len(line) <= 90 else line[:87] + "..."


          machine.wait_for_unit("multi-user.target")

          report("nix_version", machine.succeed("nix --version").strip())

          # Both sockets are up, but determinate-nixd, which writes
          # /etc/nix/nix.conf, only starts on the first connection.
          status, _ = machine.execute("test -e /etc/nix/nix.conf")
          report("nix.conf first", "absent" if status else "present")
          machine.succeed("nix store info --store daemon")
          machine.wait_for_unit("nix-daemon.service")
          for path in ("/etc/nix/nix.conf", "/etc/nix/nix.custom.conf"):
              for line in key_lines(path):
                  report(path, line)

          exec_start = machine.succeed(
              "systemctl show nix-daemon.service -p ExecStart --value"
          )
          report("nix-daemon.service ExecStart", exec_start.split(" ;")[0])
          for unit in ("determinate-nixd.socket", "nix-daemon.socket"):
              state = machine.succeed(f"systemctl is-active {unit}").strip()
              report(unit, state)
          state = machine.execute("systemctl is-active nix-daemon.service")[1]
          report("nix-daemon.service", state.strip())

          for name in ("lazy-trees", "eval-cores"):
              value = machine.succeed(f"nix config show {name}").strip()
              report(f"default {name}", value)

          # Lazy trees: a flake whose only output is 1, next to a 512 MiB blob.
          machine.succeed("mkdir /root/big")
          machine.succeed(
              "echo '{ outputs = _: { x = 1; }; }' > /root/big/flake.nix"
          )
          machine.succeed(
              "dd if=/dev/urandom of=/root/big/blob.bin bs=1M count=512 "
              "status=none"
          )

          for label, flag in (("lazy", ""), ("no_lazy", "--no-lazy-trees")):
              times = []
              delta = None
              for i in range(RUNS):
                  # Every run evaluates a fresh copy of the directory. The
                  # store grows on the first run only: later copies have the
                  # same content, hence the same store path.
                  copy = f"/root/big-{label}-{i}"
                  machine.succeed(f"cp -r /root/big {copy}")
                  before = store_mb() if i == 0 else None
                  times.append(wall_ms(f"nix eval {flag} path:{copy}#x"))
                  if i == 0:
                      delta = store_mb() - before
              report(f"lazy_trees {label} first_ms", times[0])
              report(f"lazy_trees {label} median_ms", statistics.median(times))
              report(f"lazy_trees {label} store_delta_mb", delta)

          # Parallel evaluation: eval-cores 1 is off, 0 uses every core.
          for label, cores in (("off", 1), ("on", 0)):
              times = [
                  wall_ms(
                      f"nix eval --raw --eval-cores {cores} "
                      "--file ${minimalOs}"
                  )
                  for _ in range(RUNS)
              ]
              report(f"parallel_eval {label} first_ms", times[0])
              report(f"parallel_eval {label} median_ms", statistics.median(times))
        '';
      };
    };
}
