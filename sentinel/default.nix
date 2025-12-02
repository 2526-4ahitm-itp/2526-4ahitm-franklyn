{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    project-version,
    package-meta,
    self',
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
        llvmPackages_20.libc
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
    devShells.sentinel = pkgs.mkShell {
      nativeBuildInputs =
        commonBuildInputs
        ++ platformBuildInputs
        ++ commonDevInputs
        ++ scripts;

    };

    packages.franklyn-sentinel = pkgs.rustPlatform.buildRustPackage rec {
      pname = "franklyn-sentinel";
      version = project-version;
      src = pkgs.lib.cleanSource ./.;

      cargoLock = {
        lockFile = ./Cargo.lock;
        allowBuiltinFetchGit = true;
      };

      buildType = "release";

      nativeBuildInputs = commonBuildInputs;

      buildInputs = platformBuildInputs;

      postFixup = ''
        mv $out/bin/$pname $out/bin/$pname-$version-$system
      '';

      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath platformBuildInputs;

      meta = package-meta;
    };

    packages.franklyn-sentinel-deb = pkgs.stdenv.mkDerivation {
      pname = "franklyn-sentinel-deb";
      version = project-version;

      dontUnpack = true;

      nativeBuildInputs = with pkgs; [
        dpkg
      ];

      buildPhase = ''
        ARCHITECTURE="$(dpkg --print-architecture)"
        OUT_DIR="debian-package"
        PKG_DIR="''${OUT_DIR}/''${pname}_''${version}_''${ARCHITECTURE}"

        mkdir $PKG_DIR/usr/bin -p
        mkdir $PKG_DIR/DEBIAN -p
        cp ${self'.packages.franklyn-sentinel}/bin/franklyn-sentinel-* $PKG_DIR/usr/bin/franklyn-sentinel

        echo "Package: franklyn-sentinel
        Version: $version
        Maintainer: Jakob Huemer-Fistelberger <j.huemer-fistelberger@htblaleonding.onmicrosoft.com>
        Architecture: ''${ARCHITECTURE}
        Description: Franklyn Client
        " > $PKG_DIR/DEBIAN/control

        dpkg --build $PKG_DIR
      '';

      installPhase = ''
        mkdir -p $out/lib
        mkdir -p $out/bin
        cp ${self'.packages.franklyn-sentinel}/bin/franklyn-sentinel-* $out/bin
        cp $OUT_DIR/franklyn-sentinel-*.deb $out/lib
      '';
    };
  };
}
