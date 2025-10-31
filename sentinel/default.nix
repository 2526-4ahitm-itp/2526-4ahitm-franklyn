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
        xorg.libxcb

        # Cargo tools
        cargo
        cargo-bloat # Analyze binary size
        cargo-edit # Add/remove dependencies from CLI
        cargo-outdated # Check for outdated dependencies
        cargo-udeps # Find unused dependencies
        cargo-watch # Auto-rebuild on file changes
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

    packages.sentinel = pkgs.rustPlatform.buildRustPackage rec {
      pname = "franklyn-sentinel";
      version = "0.1.0";

      src = ./.;

      cargoLock = {
        lockFile = ./Cargo.lock;
      };

      inherit nativeBuildInputs;

      OPENSSL_DIR = "${pkgs.openssl.dev}";
      OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    };
  };
}
