{inputs, ...}: {
  perSystem = {
    self',
    pkgs,
    pkgs-unstable,
    lib,
    system,
    project-version,
    package-meta,
    project-license-text,
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

        echo "=== GO LICENSE CHECK"
        nix-store --realise ${builtins.unsafeDiscardOutputDependency
          self'.packages.franklyn-server-go-licenses.drvPath}

        echo "=== GO VOLUNERABILITY CHECK"
        govulncheck ./...
      '')
      frServerGoCoverage
    ];

    go = pkgs.go-bin.fromGoMod ./go.mod;

    licenseFile = pkgs.writeText "LICENSE" project-license-text;
    allowedLicenses = [
      "MIT"
      "Apache-2.0"
      "BSD-3-Clause"
    ];

    commonDevInputs =
      (with pkgs; [
        inputs.go-overlay.packages.${system}.govendor # govendor.toml
        sqlc # sql codegen
        air # rerun on filechange
        goose # db migrations
        go-licenses
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

    packages.franklyn-server-go-licenses = pkgs.stdenv.mkDerivation {
      pname = "franklyn-server-go-licenses";
      version = project-version;

      doCheck = true;

      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.gitTracked ./.;
      };

      nativeBuildInputs = [
        pkgs.go-licenses
        pkgs.git
        go
      ];

      buildPhase = ''
        export HOME=$TMPDIR
        ln -s ${pkgs.mkVendorEnv {
          inherit go;
          manifest = fromTOML (builtins.readFile ./govendor.toml);
        }} vendor
        go-licenses save . --save_path=LICENSES
      '';

      checkPhase = ''
        if ! git --no-pager diff --no-index ${licenseFile} LICENSE; then
          echo "LICENSE CHECK FAILED: LICENSE and server-go/LICENSE do not have the same content"
          exit 1
        fi
        go-licenses check . \
          --allowed_licenses="${builtins.concatStringsSep "," allowedLicenses}"
        go-licenses check ./...
      '';

      installPhase = ''
        mkdir -p $out
        cp -r LICENSES/. $out
      '';
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
