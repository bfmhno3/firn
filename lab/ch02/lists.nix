# 列表：++、elemAt、head、tail、map、filter、genList、length。
let
  xs = [
    10
    20
    30
    40
  ];
in
{
  concat = xs ++ [ 50 ];
  second = builtins.elemAt xs 1;
  first = builtins.head xs;
  rest = builtins.tail xs;
  doubled = map (n: n * 2) xs;
  big = builtins.filter (n: n > 20) xs;
  squares = builtins.genList (i: i * i) 6;
  len = builtins.length xs;
  mixed = [
    1
    "two"
    3.0
    null
    [ ]
    { }
  ];
}
