# attrsOf (submodule …)：每个键一份子模块求值，子模块函数拿到 name。
# 两个顶层模块各定义同一个 job 的不同字段，字段按子模块的选项合并。
let
  pkgs = import ../../nix/pkgs.nix { };
  inherit (pkgs) lib;
  inherit (lib) mkOption types;

  job =
    { name, config, ... }:
    {
      options = {
        title = mkOption {
          type = types.str;
          default = "job ${name}";
        };
        sources = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
        summary = mkOption {
          type = types.str;
          readOnly = true;
        };
      };
      config.summary = "${config.title}: ${toString (builtins.length config.sources)} source(s)";
    };

  evaluated = lib.evalModules {
    modules = [
      { options.jobs = mkOption { type = types.attrsOf (types.submodule job); }; }
      {
        jobs.home.sources = [ "/home/alice" ];
        jobs.etc.title = "system config";
      }
      {
        jobs.home.sources = [ "/home/bob" ];
        jobs.etc.sources = [ "/etc" ];
      }
    ];
  };
in
lib.mapAttrs (_: j: { inherit (j) title sources summary; }) evaluated.config.jobs
