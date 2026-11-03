# 故意写错的测试：两个失败，一个通过，一个名字不以 test 开头所以被忽略。
{
  testAddWrong = {
    expr = 1 + 1;
    expected = 3;
  };
  testConcatOk = {
    expr = [ 1 ] ++ [ 2 ];
    expected = [
      1
      2
    ];
  };
  testStringWrong = {
    expr = "a" + "b";
    expected = "ba";
  };
  notATest = {
    expr = 1;
    expected = 2;
  };
}
