{
  description = "firn: companion code for the series 用 Firn 从零学 Nix";

  # 第 20 章：CI 推送到的公开 Cachix 缓存。nixConfig 里的设置要经过
  # accept-flake-config（或交互确认）才生效，见第 20 章。
  nixConfig = {
    extra-substituters = [ "https://bfmhno3-firn.cachix.org" ];
    extra-trusted-public-keys = [
      "bfmhno3-firn.cachix.org-1:LqoBOb9Jvs/LrrTa/CxBwJG14boQsOkdBEABj+M3GBI="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # 第 17 章：sops-nix，锁在 2026-08-23 之前 master 的最后一个提交。
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 第 18 章：Home Manager，同样锁在 2026-08-23 之前 master 的最后一个提交。
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      sops-nix,
      home-manager,
      ...
    }:
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
      # 第 18 章：独立的 Home Manager 配置，pkgs 带 Firn 的 overlay。
      homeFor =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          modules = [
            self.homeModules.cairn
            ./home/demo.nix
          ];
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

          # 第 20 章：tests/lib-unit.nix 交给 nix-unit 跑。沙箱里没有 /nix/var 的可写
          # 状态，所以像 nix-unit 文档说的那样把 HOME 指到构建目录，并用
          # --eval-store 把求值产物放在那里。
          lib-unit =
            pkgs.runCommand "firn-lib-unit"
              {
                src = pkgs.lib.cleanSource ./.;
                nativeBuildInputs = [ pkgs.nix-unit ];
              }
              ''
                HOME="$(realpath .)"
                export HOME
                nix-unit --eval-store "$HOME" "$src/tests/lib-unit.nix"
                echo ok > $out
              '';

          # 第 20 章：Makefile lint 目标的沙箱版。文件选择与 Makefile 一致：
          # nixfmt 看所有 .nix，statix 和 deadnix 跳过 lab/ 和 templates/。
          lint =
            pkgs.runCommand "firn-lint"
              {
                src = pkgs.lib.cleanSource ./.;
                nativeBuildInputs = with pkgs; [
                  nixfmt
                  statix
                  deadnix
                  findutils
                ];
              }
              ''
                cd "$src"
                mapfile -t all < <(find . -name '*.nix' -type f | sort)
                mapfile -t strict < <(find . -name '*.nix' -type f \
                  -not -path './lab/*' -not -path './templates/*' | sort)
                nixfmt --check "''${all[@]}"
                for f in "''${strict[@]}"; do
                  statix check "$f"
                done
                deadnix --fail "''${strict[@]}"
                echo ok > $out
              '';

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

          # Home Manager：demo 配置生成的 cairn.conf 必须逐字等于下面的文本。
          home-files =
            let
              home = homeFor system;
            in
            pkgs.runCommand "firn-home-files"
              {
                homeFiles = home.config.home-files;
                expected = pkgs.writeText "expected-cairn.conf" ''
                  repo = /home/demo/.local/share/cairn/repo
                  source = /home/demo/Documents
                  keep_last = 5
                  keep_daily = 7
                  keep_weekly = 4
                '';
              }
              ''
                diff -u "$expected" "$homeFiles/.config/cairn/cairn.conf" >&2
                echo ok > $out
              '';
        }
        # 第 16 章：cairn 的 NixOS 模块在虚拟机里跑一遍，需要 KVM。
        // pkgs.lib.optionalAttrs (system == "x86_64-linux") {
          cairn-vm = import ./nixos/tests/cairn.nix {
            inherit pkgs;
            cairnModule = self.nixosModules.default;
          };

          # 第 17 章：sops-nix 与直接写进 store 的两个节点对比。
          secrets-vm = import ./nixos/tests/secrets.nix {
            inherit pkgs;
            sopsModule = sops-nix.nixosModules.sops;
          };

          # 第 18 章：Home Manager 作为 NixOS 模块，用户级定时器在虚拟机里跑。
          # useGlobalPkgs 下用户配置里的 nixpkgs.overlays 不生效，还会触发求值警告，
          # 所以 overlay 加在系统上，用户只导入不带 overlay 的原始模块。
          home-vm = import ./nixos/tests/home.nix {
            inherit pkgs;
            homeManagerModule = home-manager.nixosModules.home-manager;
            cairnHomeModule = ./home/modules/cairn.nix;
            overlay = self.overlays.default;
          };
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

      # 第 16 章：services.cairn，以及用它搭的实验主机（只求值和构建，不装到真机）。
      nixosModules = {
        cairn = {
          imports = [ ./nixos/modules/cairn.nix ];
          nixpkgs.overlays = [ self.overlays.default ];
        };
        default = self.nixosModules.cairn;
      };

      nixosConfigurations.lab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.default
          ./nixos/hosts/lab.nix
        ];
      };

      # 第 18 章：programs.cairn，以及用它搭的独立配置 demo（只构建，不激活）。
      homeModules = {
        cairn = {
          imports = [ ./home/modules/cairn.nix ];
          nixpkgs.overlays = [ self.overlays.default ];
        };
        default = self.homeModules.cairn;
      };

      homeConfigurations.demo = homeFor "x86_64-linux";

      # nix fmt：格式化整个仓库。
      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
