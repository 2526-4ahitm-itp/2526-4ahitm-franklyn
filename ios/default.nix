{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    lib,
    ...
  }: let
    isDarwin = lib.hasSuffix "-darwin" system;

    # Nix stdenv sets DEVELOPER_DIR to the Nix Apple SDK, which doesn't
    # include the Swift toolchain. Override it to point at the real Xcode
    # so that swiftlint, xcodebuild, and xcrun work correctly.
    xcodeDevDir = "/Applications/Xcode.app/Contents/Developer";

    scripts = lib.optionals isDarwin [
      (pkgs.writeScriptBin "fr-ios-fetch-schema" ''
        set -euo pipefail

        SCHEMA_URL="''${1:-http://localhost:5050/api/graphql/schema.graphql}"

        echo "Fetching GraphQL schema from $SCHEMA_URL ..."
        mkdir -p graphql
        # Prepend custom scalar declarations that the server schema omits,
        # then append the fetched SDL.
        printf 'scalar DateTime\nscalar BigInteger\n\n' > graphql/schema.graphqls
        ${pkgs.curl}/bin/curl --fail --silent --show-error "$SCHEMA_URL" >> graphql/schema.graphqls
        echo "Schema saved to graphql/schema.graphqls"
      '')

      (pkgs.writeScriptBin "fr-ios-codegen" ''
        set -euo pipefail

        if [ ! -f graphql/schema.graphqls ]; then
          echo "Error: graphql/schema.graphqls not found. Run fr-ios-fetch-schema first."
          exit 1
        fi

        echo "Running Apollo iOS code generation..."
        ./apollo-ios-cli generate
        echo "Code generation complete."
      '')

      (pkgs.writeScriptBin "fr-ios-pr-check" ''
        set -euo pipefail

        export DEVELOPER_DIR="${xcodeDevDir}"

        swiftformat --lint .
        swiftlint lint --strict

        # Clear Nix stdenv variables that conflict with Xcode's build system
        unset CC CXX LD AR RANLIB NM STRIP
        unset NIX_LDFLAGS NIX_CFLAGS_COMPILE NIX_ENFORCE_PURITY
        unset SDKROOT

        rm -rf TestResults.xcresult
        xcodebuild test \
          -project Mobile.xcodeproj \
          -scheme Mobile \
          -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
          -enableCodeCoverage YES \
          -resultBundlePath TestResults.xcresult \
          | xcbeautify
        xcrun xccov view --report --json TestResults.xcresult > coverage.json
      '')
    ];

    commonBuildInputs = lib.optionals isDarwin (
      with pkgs; [
        swiftformat
        swiftlint
        xcbeautify
      ]
    );

    dummyserverPython = pkgs.python3.withPackages (ps: with ps; [
      fastapi
      uvicorn
      websockets
    ]);

    dummyserverScript = pkgs.writeShellScriptBin "fr-dummyserver" ''
      cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)/ios/dummyserver"
      exec ${dummyserverPython}/bin/uvicorn server:app --host 0.0.0.0 --port 8000 --reload
    '';
  in {
    devShells =
      {
        dummyserver = pkgs.mkShell {
          name = "Franklyn Dummy Chat Server";
          packages = [ dummyserverPython dummyserverScript ];
        };
      }
      // lib.optionalAttrs isDarwin {
        ios = pkgs.mkShell {
          name = "Franklyn iOS DevShell";
          packages = commonBuildInputs ++ scripts;
          shellHook = ''
            export DEVELOPER_DIR="${xcodeDevDir}"
          '';
        };
      };
  };
}
