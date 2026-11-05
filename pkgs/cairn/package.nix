{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  bash,
  bats,
  coreutils,
  findutils,
  gawk,
  gnugrep,
  gnused,
  rsync,
  util-linux,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cairn";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "bfmhno3";
    repo = "cairn";
    tag = "ch10";
    hash = "sha256-y+6fZYN1bMicL+IzPC1Wr4mrol+VEVkiDFWuxtsiSxg=";
  };

  nativeBuildInputs = [ makeWrapper ];

  # patchShebangs 只改写 buildInputs 里有的解释器：
  # bash 在这里，#!/usr/bin/env bash 才会变成 store 路径。
  buildInputs = [ bash ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    sh ./install.sh --prefix "$out"
    runHook postInstall
  '';

  # wrapProgram 把 PATH 固定到运行时依赖，包不再依赖调用者的环境。
  postFixup = ''
    wrapProgram "$out/bin/cairn" --prefix PATH : ${
      lib.makeBinPath [
        coreutils
        findutils
        gawk
        gnugrep
        gnused
        rsync
        util-linux
      ]
    }
  '';

  doCheck = true;
  nativeCheckInputs = [
    (bats.withLibraries (l: [
      l.bats-support
      l.bats-assert
      l.bats-file
    ]))
    rsync
    util-linux
    gawk
  ];
  # 构建沙箱里没有 /usr/bin/env，测试直接运行 bin/cairn，先改写它的 shebang。
  # snapshot.bats 里的假 rsync 也是 #!/usr/bin/env bash，一并改掉。
  preCheck = ''
    patchShebangs bin
    substituteInPlace tests/snapshot.bats \
      --replace-fail '#!/usr/bin/env bash' '#!${bash}/bin/bash'
  '';
  # install、completion、lock_signal 需要沙箱之外的工具或时序，不在这里跑。
  checkPhase = ''
    runHook preCheck
    bats --formatter pretty tests/cli.bats tests/config.bats tests/prune.bats \
      tests/snapshot.bats tests/verify_diff.bats tests/report.bats
    runHook postCheck
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$("$out/bin/cairn" --version)" = 'cairn ${finalAttrs.version}'
    runHook postInstallCheck
  '';

  meta = {
    description = "Incremental hard-link snapshot backups, written in Bash";
    homepage = "https://github.com/bfmhno3/cairn";
    license = [
      lib.licenses.mit
      lib.licenses.asl20
    ];
    mainProgram = "cairn";
    platforms = lib.platforms.linux;
  };
})
