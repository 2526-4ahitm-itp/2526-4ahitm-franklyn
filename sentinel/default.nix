{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    mkEnvHook,
    project-version,
    package-meta,
    maintainers,
    self',
    ...
  }: let
    scripts = [
      (pkgs.writeScriptBin "fr-sentinel-pr-check" ''
        set -eu

        cargo fmt --check
        cargo deny check license
        cargo clippy --all-targets --all-features \
          --message-format=short
        fr-sentinel-coverage
      '')
      (pkgs.writeScriptBin "fr-sentinel-build" ''
        set -e
        cargo build --release --features=prod
      '')
      (pkgs.writeScriptBin "fr-sentinel-coverage" ''
        cargo tarpaulin --out xml --lib --all-features
      '')
    ];

    rustToolchain = pkgs.rust-bin.stable.latest.default.override {
      extensions = [
        "rust-src"
        "rust-analyzer"
        "clippy"
        "rustfmt"
      ];
    };

    commonNativeBuildInputs = with pkgs; [
      rustToolchain
      pkg-config
      clang
    ];

    commonBuildInputs = with pkgs; [
      llvmPackages.libclang
      openssl
    ];

    linuxBuildInputs = with pkgs; [
      pipewire
      wayland
      libglvnd
      libgbm
      xorg.libX11
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXi
      xorg.libXinerama
      xorg.libXext
      xorg.libXrender
      xorg.libXxf86vm
      libxcb
    ];

    platformBuildInputs =
      pkgs.lib.optionals pkgs.stdenv.isLinux linuxBuildInputs
      ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [];

    commonDevInputs = with pkgs; [
      cargo-deny
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
  in {
    devShells.sentinel = pkgs.mkShell {
      name = "Franklyn Sentinel DevShell";
      packages =
        commonNativeBuildInputs
        ++ commonBuildInputs
        ++ platformBuildInputs
        ++ commonDevInputs
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

      nativeBuildInputs = commonNativeBuildInputs;

      buildInputs = commonBuildInputs ++ platformBuildInputs;

      LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

      buildFeatures = [
        "prod"
      ];

      postFixup = ''
        mv $out/bin/$pname $out/bin/$pname-$version-$system
      '';

      meta = package-meta;
    };

    packages.franklyn-sentinel-deb = pkgs.stdenv.mkDerivation {
      pname = "franklyn-sentinel";
      version = builtins.replaceStrings ["-"] ["~"] project-version;

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
        Maintainer: ${maintainers.jakob.name} <${maintainers.jakob.email}>
        Architecture: ''${ARCHITECTURE}
        Description: Franklyn Client" > $PKG_DIR/DEBIAN/control

        dpkg --build $PKG_DIR
      '';

      installPhase = ''
        mkdir -p $out/lib
        mkdir -p $out/bin
        cp ${self'.packages.franklyn-sentinel}/bin/franklyn-sentinel-* $out/bin
        cp $OUT_DIR/franklyn-sentinel*.deb $out/lib
      '';

      meta = package-meta;
    };
  };
}
