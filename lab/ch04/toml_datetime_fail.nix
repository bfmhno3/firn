# fromTOML 不支持 TOML 的日期时间类型，解析阶段就报错；tryEval 也接不住。
builtins.fromTOML "released = 1979-05-27T07:32:00Z"
