# deepSeq 把整个结构求值一遍，毒药 thunk 会炸。
builtins.deepSeq { a = throw "x"; } "unreachable"
