# services.cairn 的虚拟机测试：启动一个 NixOS 节点，跑两次快照，
# 检查硬链接、定时器，并把测得的数值以 `firn: <key> <value>` 打印出来。
{ pkgs, cairnModule }:
pkgs.testers.runNixOSTest {
  name = "cairn";

  # 默认节点共用测试的只读 pkgs，不允许再设 nixpkgs.overlays；
  # nixosModules.cairn 要自己加 overlay，所以关掉只读。
  node.pkgsReadOnly = false;

  nodes.machine = {
    imports = [ cairnModule ];
    services.cairn.enable = true;
    services.cairn.settings.cairn.sources = [ "/srv/data" ];
  };

  testScript = ''
    import re

    conf = "/etc/cairn/cairn.conf"
    # root 直接跑会在仓库里留下 root 的文件，所以命令行也用 cairn 用户。
    cairn = f"runuser -u cairn -- cairn -c {conf}"


    def report(key, value):
        print(f"firn: {key} {value}")


    machine.wait_for_unit("multi-user.target")
    machine.succeed("mkdir -p /srv/data")
    machine.succeed("echo alpha > /srv/data/a.txt")
    machine.succeed("echo beta > /srv/data/b.txt")

    machine.succeed("systemctl start cairn.service")
    listing = machine.succeed(f"{cairn} list")
    snapshots = listing.strip().splitlines()[1:]
    assert len(snapshots) == 1, listing
    report("snapshots_after_first", len(snapshots))
    verified = machine.succeed(f"{cairn} verify")
    assert verified.startswith("ok "), verified
    # 快照名带时间戳，只报告前缀。
    report("verify", verified.split()[0])

    machine.succeed("echo gamma > /srv/data/b.txt")
    machine.succeed("sleep 1")
    machine.succeed("systemctl start cairn.service")
    listing = machine.succeed(f"{cairn} list")
    snapshots = listing.strip().splitlines()[1:]
    assert len(snapshots) == 2, listing
    report("snapshots_after_second", len(snapshots))

    links = machine.succeed(
        "stat -c %h /var/lib/cairn/repo/latest/srv/data/a.txt"
    ).strip()
    assert links == "2", links
    report("hardlinks_unchanged", links)
    changed = machine.succeed(
        "stat -c %h /var/lib/cairn/repo/latest/srv/data/b.txt"
    ).strip()
    assert changed == "1", changed
    report("hardlinks_changed", changed)

    timers = machine.succeed("systemctl list-timers")
    assert "cairn.timer" in timers, timers
    report("timer", "cairn.timer")

    security = machine.succeed(
        "systemd-analyze security cairn.service --no-pager"
    )
    match = re.search(
        r"Overall exposure level for cairn.service: ([0-9.]+) (\w+)",
        security,
    )
    assert match, security
    report("exposure", match.group(1))
    report("exposure_level", match.group(2))
  '';
}
