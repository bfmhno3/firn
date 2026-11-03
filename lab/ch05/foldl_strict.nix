# builtins.foldl' 是严格的左折叠，不增加调用深度，
# 同样的 1000000 个数相加可以求值。
builtins.foldl' builtins.add 0 (builtins.genList (i: i + 1) 1000000)
