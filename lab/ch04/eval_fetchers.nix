# 求值期 fetcher：在求值过程中下载，结果直接是 store 路径，不经过构建沙箱。
# 这些调用本身就是“求值时有副作用”的例子；有 hash 的版本是可复现的。
let
  cairnTag = "ch10";
  cairnRev = "3febd7b1a00b7dcbb94d6c6258d38327e3bb24d1";
in
{
  # 不带 hash：照抓不误，只在 --impure 下合法，结果有 TTL 缓存。
  fetchurl = builtins.fetchurl "https://raw.githubusercontent.com/bfmhno3/cairn/${cairnTag}/README.md";
  # 带 sha256（解包后目录的 NAR 哈希，SRI 形式）：纯模式也能用。
  fetchTarball = builtins.fetchTarball {
    url = "https://github.com/bfmhno3/cairn/archive/refs/tags/${cairnTag}.tar.gz";
    sha256 = "sha256-y+6fZYN1bMicL+IzPC1Wr4mrol+VEVkiDFWuxtsiSxg=";
  };
  fetchGit = builtins.fetchGit {
    url = "https://github.com/bfmhno3/cairn";
    ref = "refs/tags/${cairnTag}";
    rev = cairnRev;
  };
  fetchTree = builtins.fetchTree {
    type = "github";
    owner = "bfmhno3";
    repo = "cairn";
    rev = cairnRev;
  };
  # fetchGit 的返回值是属性集，不只是路径。
  fetchGitRev =
    (builtins.fetchGit {
      url = "https://github.com/bfmhno3/cairn";
      ref = "refs/tags/${cairnTag}";
      rev = cairnRev;
    }).rev;
}
