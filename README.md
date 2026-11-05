# firn

Companion code for the blog series "用 Firn 从零学 Nix" (learning Nix from scratch by growing `firn`: a small library,
a from-scratch package set, real packages, modules, a NixOS service and CI, all in one flake). Everything runs on
Nix 2.34 with one pinned nixpkgs (see `flake.lock`).

Each chapter is one git tag, `ch01` to `ch20`. Check out a tag to see the repository exactly as the post describes it.

## Chapters

<!-- chapters:begin -->
| Chapter | Topic | Post |
| --- | --- | --- |
| `ch01` | 第一次求值：nix repl、三副面孔与一段历史 | `/posts/nix-by-firn-01-first-eval/` |
| `ch02` | 值与类型：attrset、list、字符串与路径 | `/posts/nix-by-firn-02-values-and-types/` |
| `ch03` | 函数与惰性求值：thunk、seq 与不动点 | `/posts/nix-by-firn-03-functions-and-laziness/` |
| `ch04` | builtins 深挖：import、文件、JSON、正则与字符串上下文 | `/posts/nix-by-firn-04-builtins/` |
| `ch05` | 自己写一个 lib：递归、错误处理与测试 | `/posts/nix-by-firn-05-own-lib/` |
| `ch06` | derivation 与 /nix/store：.drv、哈希与沙箱 | `/posts/nix-by-firn-06-derivations-and-store/` |
| `ch07` | 从零写 stdenv，再拆开 nixpkgs 的 stdenv | `/posts/nix-by-firn-07-stdenv-from-scratch/` |
| `ch08` | flake：inputs、outputs、flake.lock 与纯求值 | `/posts/nix-by-firn-08-flakes/` |
| `ch09` | 两代 CLI：nix-env、nix-build、nix-shell 与 nix profile | `/posts/nix-by-firn-09-cli-generations/` |
| `ch10` | nixpkgs：callPackage、override、overlay 与 fetcher | `/posts/nix-by-firn-10-callpackage-overrides-overlays/` |
| `ch11` | 打包真项目：Cairn、Sift 与 Pebble | `/posts/nix-by-firn-11-packaging-real-projects/` |
| `ch12` | 交叉编译与静态链接：pkgsCross、pkgsStatic 与 splicing | `/posts/nix-by-firn-12-cross-and-static/` |
| `ch13` | 开发环境：devShell、direnv 与 templates | `/posts/nix-by-firn-13-devshells-direnv-templates/` |
| `ch14` | 给 nixpkgs 提 PR：by-name、nixpkgs-review 与 channel | `/posts/nix-by-firn-14-contributing-to-nixpkgs/` |
| `ch15` | 模块系统：从零写一个，再读懂 lib.evalModules | `/posts/nix-by-firn-15-module-system/` |
| `ch16` | NixOS：services.cairn、VM 测试与一次 switch | `/posts/nix-by-firn-16-nixos-module-and-vm-test/` |
| `ch17` | secrets：为什么不能进 store，以及 sops-nix | `/posts/nix-by-firn-17-secrets/` |
| `ch18` | Home Manager：programs.cairn 与用户级配置 | `/posts/nix-by-firn-18-home-manager/` |
| `ch19` | Determinate、FlakeHub 与 Nix 的分叉们 | `/posts/nix-by-firn-19-determinate-and-forks/` |
| `ch20` | 工程化：CI、Cachix、lint 与可复现性 | `/posts/nix-by-firn-20-engineering/` |
<!-- chapters:end -->

The posts live at <https://bfmhno3.github.io>.

## Layout

```text
flake.nix, flake.lock   the flake; nixpkgs is pinned in the lock file
nix/pins.nix            reads flake.lock, fetches the same nixpkgs without flakes
nix/pkgs.nix            `import` of that nixpkgs, for labs
default.nix, shell.nix  legacy entry points: `nix-build -A mini.hello`, `nix-shell`
pkgs/                   real packages, one `package.nix` each: firn-hello, cairn, sift, pebble, firn-tools, cairn-report
overlays/default.nix    adds every `pkgs/*` package to nixpkgs
scripts/chapter.sh      lab runner
lib/                    Firn's own library (no nixpkgs): trivial, attrsets, fixed-points, strings, importers, sources, readme, lists, generators, debug
data/chapters.toml      the 20 chapters; the table above is rendered from it (`lab/ch04/render_table.nix`)
tests/lib.nix           lib tests on `runTests`: `nix eval --file tests/lib.nix` prints `[ ]`; also the flake check `lib-tests`
lab/chNN/               small experiments, one directory per chapter
Makefile                entry points: chNN, chapters, lint, check, ci, clean
```

Lab conventions, enforced by `scripts/chapter.sh`:

- Each top-level `*.sh` or `*.nix` file of `lab/chNN/` runs in a fresh sandbox (`$LAB_TMP`) with `$FIRN_ROOT` set to the
  repository root. `*.nix` files run as `nix eval --file`. Stdout, stderr and the exit status go to
  `out/chNN/<name>.{stdout,stderr,status}`.
- `*_fail.*` must exit non-zero, every other lab must exit 0.
- `*_host.*` is skipped when `CI=true`.
- Flake-based labs only see git-tracked files: run `git add -A` before `make chNN`.

## Flake outputs

`nix flake show` lists them; every output has a comment in `flake.nix`. `<sys>` is `x86_64-linux` or `aarch64-linux`.

| Output | Contents |
| --- | --- |
| `lib` | Firn's own library (no nixpkgs) |
| `devShells.<sys>.default` | the dev shell: `nix develop` |
| `packages.<sys>.{default,firn-hello,firn-hello-hallo,cairn,sift,pebble,firn-tools,cairn-report}` | `nix build .#cairn` |
| `packages.x86_64-linux.{firn-hello-static,firn-hello-musl,firn-hello-aarch64}` | firn-hello from `pkgsStatic`, `pkgsMusl` and `pkgsCross.aarch64-multiplatform` |
| `overlays.default` | the `pkgs/*` packages as a nixpkgs overlay |
| `checks.<sys>.{dev-shell,lib-tests,readme-table,mini-site,pkg-*}` | `nix flake check`; one `pkg-<name>` build per package |
| `legacyPackages.<sys>.mini` | the from-scratch package set |
| `apps.<sys>.mini-hello` | `nix run .#mini-hello` prints the mini greeting |
| `formatter.<sys>` | `nixfmt-tree`: `nix fmt` |

## Without flakes

`default.nix` and `shell.nix` give the same packages and tools to the legacy CLI. `nix/pins.nix` reads the nixpkgs revision
from `flake.lock`, so both paths use one nixpkgs.

```bash
nix-build -A mini.hello    # same store path as: nix build .#legacyPackages.<sys>.mini.hello
nix-shell                  # nixfmt, statix, deadnix, jq (no flake needed)
```

## Running

```bash
nix develop
make ch01      # run the labs of one chapter
make ci        # lint + every chapter + nix flake check
make check     # flake checks: dev-shell, lib-tests, readme-table
```

## License

Licensed under either of [Apache License 2.0](LICENSE-APACHE) or [MIT license](LICENSE-MIT) at your option.
