# abort 不能被 tryEval 捕获，整个求值直接终止。
builtins.tryEval (abort "fatal")
