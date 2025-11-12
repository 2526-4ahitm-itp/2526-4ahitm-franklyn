{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    ...
  }: let
    nativeBuildInputs = with pkgs;
      [
        rust-bin.stable.latest.default

        # additional needed tools
        pkg-config
        openssl

        # Cargo tools
        cargo
        cargo-bloat # Analyze binary size
        cargo-edit # Add/remove dependencies from CLI
        cargo-outdated # Check for outdated dependencies
        cargo-udeps # Find unused dependencies
        cargo-watch # Auto-rebuild on file changes

        reviewdog

        (pkgs.writeScriptBin "fr-sentinel-pr-check" ''
          set +e
          failed=0

          cargo fmt --check || failed=1

#          cargo clippy --all-targets --all-features \
#            --message-format=short 2> clippy_report.txt || failed=1

          cargo clippy --all-targets --all-features \
            --message-format=short || failed=1

          cargo test || failed=1

          exit $failed
        '')
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
        pkgs.darwin.apple_sdk.frameworks.Security
        pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
      ];
  in {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.rust-overlay.overlays.default
      ];
    };

    devShells.sentinel = pkgs.mkShell {
      inherit nativeBuildInputs;
    };
  };
}
