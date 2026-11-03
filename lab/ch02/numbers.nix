# 浮点误差、toString 的浮点格式。整数溢出见 int_overflow_fail.nix（如果会报错）。
{
  floatSum = 0.1 + 0.2;
  floatSumEq = 0.1 + 0.2 == 0.3;
  toStringOne = toString 1.0;
  toStringFrac = toString 0.5;
  intMax = 9223372036854775807;
  intMin = -9223372036854775807 - 1;
  toJsonFloat = builtins.toJSON 1.0;
}
