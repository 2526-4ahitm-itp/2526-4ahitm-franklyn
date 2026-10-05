{inputs, ...}: {
  perSystem = {
    pkgs,
    pkgs-unstable,
    system,
    project-version,
    package-meta,
    ...
  }: let
    scripts = [
      (pkgs.writeShellScriptBin "fr-server-go-pr-check" ''
        set -euo pipefail
        sqlc vet
        sqlc diff

        go mod tidy -diff
        govendor && git diff --exit-code govendor.toml

        test -z "$(gofmt -l .)" || { gofmt -l .; exit 1; }
        go vet ./...
        golangci-lint run ./...

        go build ./...
        go test ./...

        govulncheck ./...
      '')
    ];

    go = pkgs.go-bin.fromGoMod ./go.mod;

    commonDevInputs =
      (with pkgs; [
        inputs.go-overlay.packages.${system}.govendor # govendor.toml
        sqlc # sql codegen
        air # rerun on filechange
        goose # db migrations
        pkgs-unstable.golangci-lint
        pkgs-unstable.govulncheck
      ])
      ++ [
        go
      ];
  in {
    devShells.server-go = pkgs.mkShell {
      name = "Franklyn Go Server DevShell";
      packages = commonDevInputs ++ scripts;
    };

    packages.franklyn-server-go = pkgs.buildGoApplication {
      inherit go;
      pname = "franklyn-server-go";
      version = project-version;

      doCheck = false;

      src = ./.;
      modules = ./govendor.toml;

      meta = package-meta;
    };
  };
}
