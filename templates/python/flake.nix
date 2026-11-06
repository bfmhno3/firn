{
  description = "A Python project with a Nix package and a dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.python3Packages.buildPythonApplication {
            pname = "hello";
            version = "0.1.0";
            pyproject = true;

            src = pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = pkgs.lib.fileset.unions [
                ./pyproject.toml
                ./src
              ];
            };

            build-system = [ pkgs.python3Packages.hatchling ];

            meta = {
              description = "Prints a greeting from a template";
              mainProgram = "hello";
            };
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            inputsFrom = [ self.packages.${system}.default ];
            packages = with pkgs; [
              ruff
              python3Packages.pytest
            ];
          };
        }
      );
    };
}
