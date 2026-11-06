{
  description = "firn: companion code for the series 用 Firn 从零学 Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      # 每个系统一份 pkgs，带上 Firn 自己的 overlay。
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      packagesFor =
        system:
        {
          inherit (pkgsFor system)
            firn-hello
            cairn
            sift
            pebble
            firn-tools
            cairn-report
            ;
          firn-hello-hallo = (pkgsFor system).firn-hello.override { greeting = "Hallo"; };
          default = (pkgsFor system).firn-hello;
        }
        # overlay 会一路带进 pkgsStatic、pkgsMusl、pkgsCross.*：它们由 nixpkgsFun
        # 重新 import nixpkgs，参数是 args // newArgs：pkgsCross 不动 overlays，
        # 原样沿用 args 里的；pkgsStatic、pkgsMusl 先替换 overlays，再把调用者的
        # overlays 追加回去（stage.nix、variants.nix 里的 `++ overlays`）。
        # 所以这些包集里的 firn-hello 仍然是 Firn 的。
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          firn-hello-static = (pkgsFor system).pkgsStatic.firn-hello;
          firn-hello-musl = (pkgsFor system).pkgsMusl.firn-hello;
          firn-hello-aarch64 = (pkgsFor system).pkgsCross.aarch64-multiplatform.firn-hello;
        };
      devShellFor =
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.mkShell {
          packages = with pkgs; [
            nixfmt
            nixfmt-tree
            statix
            deadnix
            nixd
            nil
            nix-tree
            nix-output-monitor
            nvd
            nix-diff
            nix-unit
            nixpkgs-review
            nixpkgs-vet
            nixpkgs-hammering
            nixf-diagnose
            nix-update
            nurl
            nix-init
            sops
            age
            ssh-to-age
            cachix
            fh
            direnv
            nix-direnv
            hyperfine
            jq
            gnumake
            git
            shellcheck
            shfmt
            file
            patchelf
            graphviz
          ];
          shellHook = ''
            export FIRN_DEVSHELL=1
            export FIRN_NIX_DIRENV="${pkgs.nix-direnv}/share/nix-direnv/direnvrc"
            echo "firn dev shell: $(nix --version), nixfmt $(nixfmt --version), statix ${pkgs.statix.version}, $(deadnix --version)"
          '';
        };
      devShells = forAllSystems devShellFor;
      # 第 13 章：C 和 Python 项目的开发环境。c 借 firn-hello 的构建依赖，
      # python 不需要 C 编译器，用 mkShellNoCC。
      projectShellsFor =
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          c = pkgs.mkShell {
            inputsFrom = [ pkgs.firn-hello ];
            packages = with pkgs; [
              gdb
              clang-tools
            ];
          };
          python = pkgs.mkShellNoCC {
            packages = with pkgs; [
              (python3.withPackages (ps: [
                ps.sqlalchemy
                ps.typer
                ps.rich
                ps.pytest
              ]))
              ruff
              uv
            ];
          };
        };
      firnLib = import ./lib;
      inherit (firnLib.importTOML ./data/chapters.toml) chapters;
      miniFor =
        system:
        import ./mini {
          busybox = (pkgsFor system).pkgsStatic.busybox;
          inherit system;
        };
      checksFor =
        system:
        let
          pkgs = pkgsFor system;
          failures = import ./tests/lib.nix;
          mini = miniFor system;
        in
        {
          dev-shell = devShells.${system};

          # 失败列表非空时把它打印出来并让构建失败。
          lib-tests = pkgs.runCommand "firn-lib-tests" { } (
            if failures == [ ] then
              "echo ok > $out"
            else
              ''
                echo ${pkgs.lib.escapeShellArg (builtins.toJSON failures)} | ${pkgs.jq}/bin/jq . >&2
                exit 1
              ''
          );

          # README 里标记之间的表必须等于 renderChapterTable 的输出。
          readme-table =
            pkgs.runCommand "firn-readme-table"
              {
                readme = ./README.md;
                expected = firnLib.renderChapterTable chapters;
              }
              ''
                sed -n '/<!-- chapters:begin -->/,/<!-- chapters:end -->/p' "$readme" | sed '1d;$d' > actual
                printf '%s' "$expected" > want
                diff -u want actual >&2
                echo ok > $out
              '';

          # mini 的 site 能构建，页面里有 hello 的输出和词频表。
          mini-site = pkgs.runCommand "firn-mini-site" { } ''
            grep -q '<h1>Firn mini site</h1>' ${mini.site}/index.html
            grep -q 'Hello from mini' ${mini.site}/index.html
            grep -q '^[0-9]* cairn$' ${mini.site}/index.html
            echo ok > $out
          '';

          # 模块系统：用 nixpkgs 的 evalModules 求值 cairn-settings，
          # 渲染出的 configText 必须逐字等于 tests/fixtures/cairn.conf。
          cairn-settings =
            let
              evaluated = pkgs.lib.evalModules {
                modules = [
                  ./modules/cairn-settings.nix
                  {
                    cairn = {
                      repo = "/var/lib/cairn/repo";
                      sources = [
                        "/srv/data"
                        "/etc"
                      ];
                      excludes = [ "*.tmp" ];
                      keep.last = 10;
                      keep.weekly = 2;
                    };
                  }
                ];
              };
            in
            pkgs.runCommand "firn-cairn-settings"
              {
                expected = ./tests/fixtures/cairn.conf;
                actual = evaluated.config.cairn.configText;
                passAsFile = [ "actual" ];
              }
              ''
                diff -u "$expected" "$actualPath" >&2
                echo ok > $out
              '';
        }
        # 每个包一个 pkg-<name> 检查；default 只是别名，不重复。
        // pkgs.lib.mapAttrs' (name: pkg: pkgs.lib.nameValuePair "pkg-${name}" pkg) (
          removeAttrs (packagesFor system) [ "default" ]
        );
    in
    {
      # Firn 自己的库，不依赖 nixpkgs；第 15 章加上 evalMini 和 cairn 的设置模块。
      lib = firnLib // {
        inherit (import ./modules/mini-modules.nix) evalMini;
        modules.cairnSettings = ./modules/cairn-settings.nix;
      };

      # 把 Firn 的包加进 nixpkgs：import nixpkgs { overlays = [ firn.overlays.default ]; }。
      overlays.default = import ./overlays;

      # nix build .#firn-hello 等。
      packages = forAllSystems packagesFor;

      # nix develop 进入的开发环境。
      devShells = forAllSystems (system: { default = devShells.${system}; } // projectShellsFor system);

      # nix flake init -t github:bfmhno3/firn#python 等。
      templates = {
        c = {
          path = ./templates/c;
          description = "C project: stdenv package, Makefile and mkShell dev shell";
          welcomeText = ''
            Created a C project. Next steps:

            - `git init && git add -A`
            - `nix build && ./result/bin/hello-c`
            - `nix develop`
          '';
        };
        python = {
          path = ./templates/python;
          description = "Python project: hatchling package built with buildPythonApplication";
          welcomeText = ''
            Created a Python project. Next steps:

            - `git init && git add -A`
            - `nix run`
            - `nix develop`
          '';
        };
        default = self.templates.c;
      };

      # nix flake check 构建的东西。
      checks = forAllSystems checksFor;

      # 不属于 packages 的包集；mini 是第 7 章的从零包集。
      legacyPackages = forAllSystems (system: {
        mini = miniFor system;
      });

      # nix run .#mini-hello：运行 mini 的 hello。
      apps = forAllSystems (system: {
        mini-hello = {
          type = "app";
          program = "${(miniFor system).hello}/bin/hello";
          meta.description = "Print the greeting of the mini package set";
        };
      });

      # nix fmt：格式化整个仓库。
      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
