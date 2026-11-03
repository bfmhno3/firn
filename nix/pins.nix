# 从 flake.lock 读出 nixpkgs 的版本，让不用 flake 的代码拿到同一份 nixpkgs。
let
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  inherit (lock.nodes.nixpkgs) locked;
in
{
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${locked.rev}.tar.gz";
    sha256 = locked.narHash;
  };
}
