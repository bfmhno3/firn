{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "pebble";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "bfmhno3";
    repo = "pebble";
    tag = "tutorial-v1";
    hash = "sha256-m6RjSuHICOLMobZcDn/oMMBwmZvrnAegpUU9rAc/MkY=";
  };

  # 供应商目录（vendored crates）是一个固定输出推导，cargoHash 是它的哈希。
  cargoHash = "sha256-N6epgex2dseqHh+eiezB7KS7ude18+L2KgpwMTVAaj4=";

  cargoBuildFlags = [
    "--package"
    "pebble-cli"
  ];
  cargoTestFlags = [
    "--package"
    "pebble-cli"
  ];

  meta = {
    description = "Small scripting language and toolchain, built from scratch in Rust";
    homepage = "https://github.com/bfmhno3/pebble";
    changelog = "https://github.com/bfmhno3/pebble/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = [
      lib.licenses.mit
      lib.licenses.asl20
    ];
    mainProgram = "pebble";
    platforms = lib.platforms.unix;
  };
})
