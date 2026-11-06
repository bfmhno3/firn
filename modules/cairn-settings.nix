# cairn.conf 的设置模块：声明选项，并把它们渲染成配置文本。
# 同一个模块之后会放进 NixOS（第 16 章）和 Home Manager（第 18 章）。
{ config, lib, ... }:
let
  inherit (lib) mkOption types;
  firnLib = import ../lib;
  cfg = config.cairn;
in
{
  options.cairn = {
    repo = mkOption {
      type = types.str;
      description = "Path of the cairn repository.";
      example = "/var/lib/cairn/repo";
    };

    sources = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Directories to snapshot, one `source` line each.";
    };

    excludes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Glob patterns to leave out, one `exclude` line each.";
    };

    keep = {
      last = mkOption {
        type = types.ints.positive;
        default = 5;
        description = "Snapshots kept regardless of age (`keep_last`).";
      };
      daily = mkOption {
        type = types.ints.unsigned;
        default = 7;
        description = "Daily snapshots kept (`keep_daily`).";
      };
      weekly = mkOption {
        type = types.ints.unsigned;
        default = 4;
        description = "Weekly snapshots kept (`keep_weekly`).";
      };
    };

    configText = mkOption {
      type = types.str;
      readOnly = true;
      description = "The rendered cairn.conf.";
    };
  };

  # 属性集会按键排序，行序要靠列表：repo、source、exclude、keep_*。
  config.cairn.configText = firnLib.generators.toKeyValue { } [
    {
      name = "repo";
      value = cfg.repo;
    }
    {
      name = "source";
      value = cfg.sources;
    }
    {
      name = "exclude";
      value = cfg.excludes;
    }
    {
      name = "keep_last";
      value = cfg.keep.last;
    }
    {
      name = "keep_daily";
      value = cfg.keep.daily;
    }
    {
      name = "keep_weekly";
      value = cfg.keep.weekly;
    }
  ];
}
