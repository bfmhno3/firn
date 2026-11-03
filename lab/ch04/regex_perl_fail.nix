# Nix 的正则是 POSIX ERE：\d 这种 Perl 写法直接报 invalid regular expression。
builtins.match "\\d+" "42"
