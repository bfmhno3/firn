{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "sift";
  version = "0.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "bfmhno3";
    repo = "sift";
    tag = "ch25";
    hash = "sha256-+PhuZvOxeSTZOCqTc+RvfM17aocOInGeJzZLB+gbWLY=";
  };

  build-system = [ python3Packages.hatchling ];

  dependencies = with python3Packages; [
    sqlalchemy
    typer
    click
    rich
  ];

  pythonImportsCheck = [
    "sift"
    "sift.cli"
  ];

  # 测试套件需要 dev 额外依赖和语料库，所以没有 pytestCheckHook。
  # 不要写 doCheck = false：mk-python-derivation 用 doInstallCheck = attrs.doCheck or true，
  # 关掉 doCheck 会连带关掉下面的 installCheckPhase。

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/sift" --help | grep -q Usage
    "$out/bin/sift" --version | grep -qF '${finalAttrs.version}'
    runHook postInstallCheck
  '';

  meta = {
    description = "Local full-text search engine for Markdown posts";
    homepage = "https://github.com/bfmhno3/sift";
    license = [
      lib.licenses.mit
      lib.licenses.asl20
    ];
    mainProgram = "sift";
    platforms = lib.platforms.unix;
  };
})
