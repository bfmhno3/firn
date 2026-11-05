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
      packagesFor = system: {
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
        }
        # 每个包一个 pkg-<name> 检查；default 只是别名，不重复。
        // pkgs.lib.mapAttrs' (name: pkg: pkgs.lib.nameValuePair "pkg-${name}" pkg) (
          removeAttrs (packagesFor system) [ "default" ]
        );
    in
    {
      # Firn 自己的库，不依赖 nixpkgs。
      lib = firnLib;

      # 把 Firn 的包加进 nixpkgs：import nixpkgs { overlays = [ firn.overlays.default ]; }。
      overlays.default = import ./overlays;

      # nix build .#firn-hello 等。
      packages = forAllSystems packagesFor;

      # nix develop 进入的开发环境。
      devShells = nixpkgs.lib.mapAttrs (_: devShell: { default = devShell; }) devShells;

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
