# 练习：十个值的 builtins.typeOf。
map builtins.typeOf [
  1
  1.5
  true
  "s"
  ./.
  null
  [ ]
  { }
  (x: x)
  builtins.add
]
