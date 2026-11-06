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

  buildInputs = [ bash ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    sh ./install.sh --prefix "$out"
    runHook postInstall
  '';

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
  preCheck = ''
    patchShebangs bin
    substituteInPlace tests/snapshot.bats \
      --replace-fail '#!/usr/bin/env bash' '#!${bash}/bin/bash'
  '';
  checkPhase = ''
    runHook preCheck
    bats --formatter pretty tests/cli.bats tests/config.bats tests/prune.bats \
      tests/snapshot.bats tests/verify_diff.bats tests/report.bats
    runHook postCheck
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
    command = "cairn --version";
    version = "0.1.0";
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
