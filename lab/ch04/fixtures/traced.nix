# 被 import 时会在 stderr 打印一行；缓存生效时只打印一次。
builtins.trace "traced.nix evaluated" (x: x * 2)
