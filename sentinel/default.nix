{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    project-version,
    ...
  }: let
    linuxBuildInputs = with pkgs; [
      xorg.libxcb
      xorg.libXrandr
      dbus
      pipewire
      wayland
      libGL
      libgbm
    ];

    nativeBuildInputs = with pkgs;
      [
        rust-bin.stable.latest.default

        pkg-config
        llvmPackages.libclang.lib
        clang

        ffmpeg-full

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

          cargo clippy --all-targets --all-features \
            --message-format=short || failed=1

          cargo test || failed=1

          exit $failed
        '')

        (pkgs.writeScriptBin "fr-sentinel-build" ''
          set -e

          cargo build --release
        '')
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
        pkgs.darwin.apple_sdk.frameworks.Security
        pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux linuxBuildInputs;
  in {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.rust-overlay.overlays.default
      ];
    };

    devShells.sentinel = pkgs.mkShell {
      inherit nativeBuildInputs;

      LIBCLANG_PATH = "${pkgs.llvmPackages_16.libclang.lib}/lib";
      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (
        if pkgs.stdenv.isLinux
        then linuxBuildInputs
        else []
      );

      shellHook = ''
        export LIBCLANG_PATH="${pkgs.llvmPackages_16.libclang.lib}/lib"
      '';
    };

    packages.franklyn-sentinel = pkgs.rustPlatform.buildRustPackage rec {
      name = "franklyn-sentinel";
      version = project-version;
      cargoLock.lockFile = ./Cargo.lock;
      src = pkgs.lib.cleanSource ./.;
    };
  };
}
