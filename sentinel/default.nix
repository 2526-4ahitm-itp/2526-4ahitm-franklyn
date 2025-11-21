{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    project-version,
    package-meta,
    ...
  }: let
    scripts = [
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
    ];

    commonBuildInputs = with pkgs; [
      rust-bin.stable.latest.default

      pkg-config
      llvmPackages.libclang.lib
      clang
    ];

    platformBuildInputs =
      [pkgs.ffmpeg]
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux
      (with pkgs; [
        xorg.libxcb
        xorg.libXrandr
        dbus
        pipewire
        wayland
        wayland-protocols
        libGL
        libgbm
        udev
      ]);

    commonDevInputs = with pkgs; [
      cargo
      cargo-bloat # Analyze binary size
      cargo-edit # Add/remove dependencies from CLI
      cargo-outdated # Check for outdated dependencies
      cargo-udeps # Find unused dependencies
      cargo-watch # Auto-rebuild on file changes
    ];

    platformDevInputs =
      pkgs.lib.optionals pkgs.stdenv.isDarwin []
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux [];
  in {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.rust-overlay.overlays.default
      ];
    };

    devShells.sentinel = pkgs.mkShell {
      nativeBuildInputs =
        commonBuildInputs
        ++ platformBuildInputs
        ++ commonDevInputs
        ++ scripts;

      shellHook = ''
        export LIBCLANG_PATH="${pkgs.llvmPackages_16.libclang.lib}/lib"
      '';
    };

    packages.franklyn-sentinel = pkgs.rustPlatform.buildRustPackage rec {
      name = "franklyn-sentinel";
      version = project-version;
      src = pkgs.lib.cleanSource ./.;

      cargoLock = {
        lockFile = ./Cargo.lock;
        allowBuiltinFetchGit = true;
      };

      buildType = "release";

      nativeBuildInputs = commonBuildInputs;

      buildInputs = platformBuildInputs;

      fixupPhase = ''
        mv $out/bin/franklyn-sentinel $out/bin/franklyn-sentinel-${project-version}
      '';

      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath platformBuildInputs;
      LIBCLANG_PATH = "${pkgs.llvmPackages_16.libclang.lib}/lib";

      meta = package-meta;
    };
  };
}
