{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    mkEnvHook,
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

        fr-sentinel-coverage || failed=1

        exit $failed
      '')
      (pkgs.writeScriptBin "fr-sentinel-build" ''
        set -e
        cargo build --release
      '')
      (pkgs.writeScriptBin "fr-sentinel-coverage" ''
        cargo tarpaulin --out xml --lib --all-features
      '')
    ];

    commonBuildInputs = with pkgs; [
      rust-bin.stable.latest.default

      pkg-config
      clang
      llvmPackages.libclang

      openssl
    ];

    platformBuildInputs =
      [pkgs.ffmpeg]
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux
      (with pkgs; [
        pipewire
        wayland
        mesa
        libglvnd
        egl-wayland
        glibc.dev
        xorg.libX11
        xorg.libXcursor
        xorg.libXrandr
        xorg.libXi
        xorg.libXinerama
        xorg.libXext
        xorg.libXrender
        xorg.libXxf86vm

        libxcb
        libgbm
      ]);

    commonDevInputs = with pkgs; [
      cargo-bloat # Analyze binary size
      cargo-edit # Add/remove dependencies from CLI
      cargo-outdated # Check for outdated dependencies
      cargo-udeps # Find unused dependencies
      cargo-watch # Auto-rebuild on file changes
      cargo-tarpaulin # test coverage
      cargo-license
      cargo-msrv
      cargo-expand
    ];

    platformDevInputs =
      pkgs.lib.optionals pkgs.stdenv.isDarwin []
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux [];
  in {
    devShells.sentinel = pkgs.mkShell {
      name = "Franklyn Sentinel DevShell";
      packages =
        commonBuildInputs
        ++ platformBuildInputs
        ++ commonDevInputs
        ++ platformDevInputs
        ++ scripts;

      shellHook = ''
        ${mkEnvHook [
          {
            name = "LIBCLANG_PATH";
            value = "${pkgs.llvmPackages.libclang.lib}/lib";
          }
        ]}
      '';
    };

    packages.franklyn-sentinel = pkgs.rustPlatform.buildRustPackage rec {
      pname = "franklyn-sentinel";
      version = project-version;
      src = pkgs.lib.cleanSource ./.;

      cargoLock = {
        lockFile = ./Cargo.lock;
        allowBuiltinFetchGit = true;
      };

      nativeBuildInputs = commonBuildInputs;

      buildInputs = platformBuildInputs;

      LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

      postFixup = ''
        mv $out/bin/$pname $out/bin/$pname-$version-$system
      '';

      meta = package-meta;
    };

    packages.franklyn-sentinel-deb = pkgs.stdenv.mkDerivation {
      pname = "franklyn-sentinel";
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
        cp $OUT_DIR/franklyn-sentinel*.deb $out/lib
      '';
    };
  };
}
