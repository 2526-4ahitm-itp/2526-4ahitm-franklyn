{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    project-version,
    package-meta,
    ...
  }: let
    scripts = [
      # (pkgs.writeScriptBin "fr-server-build-clean" ''
      #   set -eu
      #   mvn clean package
      # '')
      # (pkgs.writeScriptBin "fr-server-pr-check" ''
      #   set -eu
      #   mvn clean checkstyle:check
      #   mvn clean --batch-mode verify \
      #     -DskipITs=false \
      #     -Dquarkus.package.write-transformed-bytecode-to-build-output=true
      # '')
    ];

    commonDevInputs = with pkgs; [
      inputs.go-overlay.packages.${system}.govendor # govendor.toml
      sqlc # sql codegen
      air # rerun on filechange
      goose # db migrations
    ];

    go = pkgs.go-bin.fromGoMod ./go.mod;
  in {
    devShells.server-go = pkgs.mkShell {
      name = "Franklyn Go Server DevShell";
      packages = commonDevInputs ++ scripts;
    };

    packages.franklyn-server-go = pkgs.buildGoApplication {
      inherit go;
      pname = "franklyn-server-go";
      version = project-version;

      src = ./.;
      modules = ./govendor.toml;

      meta = package-meta;
    };
  };
}
