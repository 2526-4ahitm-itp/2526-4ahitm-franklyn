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
      patchelf
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
    libPaths = pkgs.lib.makeLibraryPath (commonBuildInputs ++ platformBuildInputs);

    sentinelAttrs = {
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

      meta = package-meta;
    };
  in {
    devShells.sentinel = pkgs.mkShell {
      name = "Franklyn Sentinel DevShell";
      packages =
        commonNativeBuildInputs ++ commonBuildInputs ++ platformBuildInputs ++ commonDevInputs ++ scripts;

      shellHook = ''
        ${mkEnvHook [
          {
            name = "LIBCLANG_PATH";
            value = "${pkgs.llvmPackages.libclang.lib}/lib";
          }
        ]}
      '';
    };

    packages.franklyn-sentinel = pkgs.rustPlatform.buildRustPackage (
      sentinelAttrs
      // {
        postFixup = ''
          mv $out/bin/$pname $out/bin/$pname-$version-$system
        '';
      }
    );

    packages.franklyn-sentinel-patched = pkgs.rustPlatform.buildRustPackage (
      sentinelAttrs
      // {
        postFixup = ''
            bin="$out/bin/$pname"
            libdir="$out/lib"
          libPaths="${libPaths}"
            interpreter="${
            if system == "x86_64-linux"
            then "/lib64/ld-linux-x86-64.so.2"
            else if system == "aarch64-linux"
            then "/lib/ld-linux-aarch64.so.1"
            else ""
          }"

          if [ -n "$interpreter" ]; then
            ${pkgs.patchelf}/bin/patchelf --set-interpreter "$interpreter" "$bin"
          fi

          libdirCreated=""
          IFS=":"
          for needed in $(${pkgs.patchelf}/bin/patchelf --print-needed "$bin"); do
            found=""
              for path in $libPaths; do
                if [ -e "$path/$needed" ]; then
                  found="$path/$needed"
                  break
                fi
              done

            if [ -n "$found" ]; then
              if [ -z "$libdirCreated" ]; then
                mkdir -p "$libdir"
                libdirCreated="yes"
              fi
              cp -L "$found" "$libdir/"
            fi
          done

          ${pkgs.patchelf}/bin/patchelf --set-rpath "\$ORIGIN/../lib" "$bin"
          mv $out/bin/$pname $out/bin/$pname-$version-$system
        '';
      }
    );

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
        cp ${self'.packages.franklyn-sentinel-patched}/bin/franklyn-sentinel-* $PKG_DIR/usr/bin/franklyn

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
        cp ${self'.packages.franklyn-sentinel-patched}/bin/franklyn-sentinel-* $out/bin
        cp $OUT_DIR/franklyn-sentinel*.deb $out/lib
      '';

      meta = package-meta;
    };
  };
}
