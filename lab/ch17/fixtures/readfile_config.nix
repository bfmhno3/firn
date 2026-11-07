# BAD: builtins.readFile 把文件内容读进求值器，再拼进配置文本，
# 文本整个写进 store，任何人都能读。
let
  pkgs = import ../../../nix/pkgs.nix { };
in
pkgs.writeText "app.conf" ''
  token = ${builtins.readFile ./secret.txt}
''
