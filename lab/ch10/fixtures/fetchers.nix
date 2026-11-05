# 四个固定输出推导（FOD），都指向 bfmhno3/cairn 的标签 ch10，commit 3febd7b。
# fake = true 时把 fetchFromGitHub 的 hash 换成 lib.fakeHash，演示 fakeHash 工作流。
{
  fake ? false,
}:
let
  pkgs = import ../../../nix/pkgs.nix { };
  inherit (pkgs) lib;
  rev = "3febd7b1a00b7dcbb94d6c6258d38327e3bb24d1";
  treeHash = "sha256-y+6fZYN1bMicL+IzPC1Wr4mrol+VEVkiDFWuxtsiSxg=";
in
{
  # 单个文件：flat 模式，hash 是文件字节的 sha256。
  installSh = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/bfmhno3/cairn/${rev}/install.sh";
    hash = "sha256-gOmM4E80qTik/4JH2kqzv2sQwTqUBVfbkkXjbyi845U=";
  };
  # GitHub 生成的 tarball 当作普通文件：flat 模式，hash 是 .tar.gz 字节的 sha256。
  tarball = pkgs.fetchurl {
    url = "https://github.com/bfmhno3/cairn/archive/refs/tags/ch10.tar.gz";
    hash = "sha256-klYYGug+UKdeu0kHZ5o17A7CSIGSImy+3cipzH0ZeY8=";
  };
  # 解包后的目录树：nar 模式，hash 是目录的 NAR 序列化的 sha256。
  fromGitHub = pkgs.fetchFromGitHub {
    owner = "bfmhno3";
    repo = "cairn";
    tag = "ch10";
    hash = if fake then lib.fakeHash else treeHash;
  };
  # 直接用 git 取同一个 commit，目录树相同，所以 hash 也相同。
  fromGit = pkgs.fetchgit {
    url = "https://github.com/bfmhno3/cairn";
    inherit rev;
    hash = treeHash;
  };
}
