# firn

Companion code for the blog series "用 Firn 从零学 Nix" (learning Nix from scratch by growing `firn`: a small library,
a from-scratch package set, real packages, modules, a NixOS service and CI, all in one flake). Everything runs on
Nix 2.34 with one pinned nixpkgs (see `flake.lock`).

Each chapter is one git tag, `ch01` to `ch20`. Check out a tag to see the repository exactly as the post describes it.

## Chapters

| Chapter | Topic | Post |
| --- | --- | --- |
| `ch01` | nix repl, three faces of Nix | `/posts/nix-by-firn-01-first-eval/` |
| `ch02` | values and types | `/posts/nix-by-firn-02-values-and-types/` |
| `ch03` | functions, laziness, fixed points | `/posts/nix-by-firn-03-functions-and-laziness/` |
| `ch04` | builtins, string context, IFD | `/posts/nix-by-firn-04-builtins/` |
| `ch05` | writing a lib: recursion, tests, debugging | `/posts/nix-by-firn-05-own-lib/` |
| `ch06` | derivations and the store | `/posts/nix-by-firn-06-derivations-and-store/` |
| `ch07` | stdenv from scratch | `/posts/nix-by-firn-07-stdenv-from-scratch/` |
| `ch08` | flakes | `/posts/nix-by-firn-08-flakes/` |
| `ch09` | two CLI generations | `/posts/nix-by-firn-09-cli-generations/` |
| `ch10` | callPackage, override, overlays | `/posts/nix-by-firn-10-callpackage-overrides-overlays/` |
| `ch11` | packaging real projects | `/posts/nix-by-firn-11-packaging-real-projects/` |
| `ch12` | cross compilation and static linking | `/posts/nix-by-firn-12-cross-and-static/` |
| `ch13` | dev shells, direnv, templates | `/posts/nix-by-firn-13-devshells-direnv-templates/` |
| `ch14` | contributing to nixpkgs | `/posts/nix-by-firn-14-contributing-to-nixpkgs/` |
| `ch15` | the module system | `/posts/nix-by-firn-15-module-system/` |
| `ch16` | NixOS module and VM test | `/posts/nix-by-firn-16-nixos-module-and-vm-test/` |
| `ch17` | secrets | `/posts/nix-by-firn-17-secrets/` |
| `ch18` | Home Manager | `/posts/nix-by-firn-18-home-manager/` |
| `ch19` | Determinate, FlakeHub, forks | `/posts/nix-by-firn-19-determinate-and-forks/` |
| `ch20` | CI, binary caches, lint | `/posts/nix-by-firn-20-engineering/` |

The posts live at <https://bfmhno3.github.io>.

## Layout

```text
flake.nix, flake.lock   the flake; nixpkgs is pinned in the lock file
nix/pins.nix            reads flake.lock, fetches the same nixpkgs without flakes
nix/pkgs.nix            `import` of that nixpkgs, for labs
scripts/chapter.sh      lab runner
lib/                    Firn's own library (no nixpkgs): trivial, attrsets, fixed-points, ...
tests/lib.nix           lib tests: `nix eval --file tests/lib.nix` prints `[ ]`
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

## Running

```bash
nix develop
make ch01      # run the labs of one chapter
make ci        # lint + every chapter
```

## License

Licensed under either of [Apache License 2.0](LICENSE-APACHE) or [MIT license](LICENSE-MIT) at your option.
