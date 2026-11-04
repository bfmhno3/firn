# 手算 store path：只做 "text" 类型（builtins.toFile、writeText 用的那种）。
# 规格见 https://nix.dev/manual/nix/2.34/protocols/store-path。
let
  hexDigits = "0123456789abcdef";

  # "0".."f" 到 0..15 的查找表。
  hexValue = builtins.listToAttrs (
    builtins.genList (i: {
      name = builtins.substring i 1 hexDigits;
      value = i;
    }) 16
  );

  # 把 64 个十六进制字符拆成 32 个字节（0..255）。
  hexToBytes =
    hex:
    builtins.genList (
      i:
      hexValue.${builtins.substring (2 * i) 1 hex} * 16 + hexValue.${builtins.substring (2 * i + 1) 1 hex}
    ) (builtins.stringLength hex / 2);

  byteToHex =
    byte:
    builtins.substring (byte / 16) 1 hexDigits
    + builtins.substring (builtins.bitAnd byte 15) 1 hexDigits;

  # 对应 Nix 的 compressHash：第 i 个字节异或进第 i % 20 个槽。
  # 32 字节折成 20 字节，所以槽 0..11 各收两个字节，其余各收一个。
  compress20 =
    bytes:
    builtins.genList (
      j:
      if j + 20 < builtins.length bytes then
        builtins.bitXor (builtins.elemAt bytes j) (builtins.elemAt bytes (j + 20))
      else
        builtins.elemAt bytes j
    ) 20;

  # store path 的 digest：20 字节的哈希，恰好和 sha1 一样长，
  # 所以可以借 convertHash 的 sha1 分支把十六进制转成 nix32。
  nix32Of20Bytes =
    bytes:
    builtins.convertHash {
      hash = builtins.concatStringsSep "" (map byteToHex bytes);
      hashAlgo = "sha1";
      toHashFormat = "nix32";
    };

  # name 必须是合法的 store path 名字这一点交给 Nix 去检查；这里只算哈希。
  # references 按路径字符串排序再进指纹；lab/ch06/ex_two_refs.nix 用两个引用
  # 验证了列表顺序不影响结果。
  textStorePath =
    {
      name,
      content,
      references ? [ ],
    }:
    let
      refs = builtins.sort builtins.lessThan (map builtins.unsafeDiscardStringContext references);
      innerDigest = builtins.hashString "sha256" (builtins.unsafeDiscardStringContext content);
      fingerprint = builtins.concatStringsSep ":" (
        [ "text" ]
        ++ refs
        ++ [
          "sha256"
          innerDigest
          "/nix/store"
          name
        ]
      );
      digest = nix32Of20Bytes (compress20 (hexToBytes (builtins.hashString "sha256" fingerprint)));
    in
    "/nix/store/${digest}-${name}";
in
{
  inherit textStorePath;
}
