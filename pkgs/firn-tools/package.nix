{
  symlinkJoin,
  firn-hello,
  cairn,
  sift,
  pebble,
}:

symlinkJoin {
  name = "firn-tools";
  paths = [
    firn-hello
    cairn
    sift
    pebble
  ];
}
