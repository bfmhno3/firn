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
  testers,
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

  # nixpkgs-vet (NPV-164、NPV-166) 要求新包打开这两项。
  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [ makeWrapper ];

  # patchShebangs 在 PATH 上找解释器：buildInputs 里的 bash 排在 stdenv 自带的
  # bash 之前，所以 #!/usr/bin/env bash 会指向 pkgs.bash (bash-interactive)。
  # 去掉这一行也会被改写，只是改成 stdenv 的 bash，闭包小约 7.6 MiB。
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
  # 这里只跑 cli、config、prune、snapshot、verify_diff、report 六个文件（81 个测试）；
  # install.bats 在沙箱里不能通过（34/35），completion 和 lock_signal 实测能通过，但没有列入。
  checkPhase = ''
    runHook preCheck
    bats --formatter pretty tests/cli.bats tests/config.bats tests/prune.bats \
      tests/snapshot.bats tests/verify_diff.bats tests/report.bats
    runHook postCheck
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
  };

  meta = {
    description = "Incremental hard-link snapshot backups, written in Bash";
    homepage = "https://github.com/bfmhno3/cairn";
    license = [
      lib.licenses.mit
      lib.licenses.asl20
    ];
    mainProgram = "cairn";
    platforms = lib.platforms.linux;
    # 真正的 PR 要先把作者加进 maintainers/maintainer-list.nix，
    # 再把 handle 写进这里；本地演练留空。
    maintainers = [ ];
  };
})
