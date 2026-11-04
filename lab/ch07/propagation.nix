# 几个锁定版 nixpkgs 包的依赖分类：nativeBuildInputs（跑在构建机上）、
# buildInputs（链接进产物）、propagatedBuildInputs（依赖它的包也会拿到）和
# strictDeps。名字取自 derivation 的 name。
let
  pkgs = import ../../nix/pkgs.nix { };
  names = map (d: d.name or "(${builtins.typeOf d})");
  describe = p: {
    nativeBuildInputs = names (p.nativeBuildInputs or [ ]);
    buildInputs = names (p.buildInputs or [ ]);
    propagatedBuildInputs = names (p.propagatedBuildInputs or [ ]);
    propagatedNativeBuildInputs = names (p.propagatedNativeBuildInputs or [ ]);
    strictDeps = p.strictDeps or false;
  };
in
{
  hello = describe pkgs.hello;
  libpng = describe pkgs.libpng;
  pkg-config = describe pkgs.pkg-config;
  curl = describe pkgs.curl;
  python3 = describe pkgs.python3;
}
