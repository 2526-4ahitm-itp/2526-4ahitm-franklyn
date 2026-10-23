{inputs, ...}: {
  perSystem = {
    self',
    pkgs,
    pkgs-unstable,
    system,
    project-version,
    package-meta,
    ...
  }: let
    frServerGoCoverage = pkgs.writeShellScriptBin "fr-server-go-coverage" ''
      set -euo pipefail
      go test -covermode=atomic \
        -coverpkg="$(go list ./... | grep -v /itest | paste -sd,)" \
        -coverprofile=coverage.txt ./...

      printf '%s\n' "$(grep -vF -f <(grep -rl 'DO NOT EDIT\.' \
        --include='*.go' . | sed 's|^\./||') coverage.txt)" > coverage.txt

      go tool cover -func=coverage.txt
    '';
    scripts = [
      (pkgs.writeShellScriptBin "fr-server-go-pr-check" ''
        set -euo pipefail
        echo "=== SQLC CHECKS"
        sqlc vet
        sqlc diff

        echo "=== PROTOBUF CHECKS"
        (cd ../protobuf && buf lint && buf format -d --exit-code && buf generate)
        drift=$(git status --porcelain -- internal/)
        test -z "$drift" || { echo "$drift"; git diff -- internal/; exit 1; }

        echo "=== GO MOD TIDY AND GOVENDOR CHECK"
        go mod tidy -diff
        govendor && git diff --exit-code govendor.toml

        echo "=== GO FORMAT"
        test -z "$(gofmt -l .)" || { gofmt -l .; exit 1; }
        echo "=== GO VET"
        go vet ./...
        echo "=== GO LINT"
        golangci-lint run ./...

        echo "=== GO BUILD"
        go build ./...
        echo "=== GO TEST AND COVERAGE"
        ${frServerGoCoverage}/bin/fr-server-go-coverage

        echo "=== GO VOLUNERABILITY CHECK"
        govulncheck ./...
      '')
      frServerGoCoverage
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
      inputsFrom = [
        self'.devShells.ci
      ];
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

      CGO_ENABLED = "0";

      meta = package-meta;
    };
  };
}
