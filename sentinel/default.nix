{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    mkEnvHook,
    project-version,
    project-license-text,
    package-meta,
    maintainers,
    lib,
    self',
    ...
  }: let
    licenseFile = pkgs.writeText "LICENSE" project-license-text;
    versionFile = pkgs.writeText "VERSION" project-version;

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
      cargo-bundle-licenses
    ];

    commonBuildInputs = with pkgs; [
      llvmPackages.libclang
      openssl

      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-libav
      gst_all_1.gst-rtsp-server
      gst_all_1.gst-editing-services
    ];

    linuxBuildInputs = with pkgs; [
      pipewire
      xdg-desktop-portal
      xdg-desktop-portal-gnome
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

    craneLib = inputs.crane.mkLib pkgs;

    commonArgs = {
      pname = "franklyn-sentinel";
      version = project-version;
      src = craneLib.cleanCargoSource ./.;

      nativeBuildInputs = commonNativeBuildInputs;

      buildInputs = commonBuildInputs ++ platformBuildInputs;

      LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
      LICENSE_PATH = "${licenseFile}";
      VERSION_PATH = "${versionFile}";

      buildFeatures = [
        "prod"
      ];

      meta = package-meta;
    };

    cargoArtifacts = craneLib.buildDepsOnly (commonArgs
      // {
        pname = "${commonArgs.pname}-deps";
      });

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
      LICENSE_PATH = "${licenseFile}";
      VERSION_PATH = "${versionFile}";

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

    packages.franklyn-sentinel = craneLib.buildPackage (commonArgs
      // {
        inherit cargoArtifacts;

        postFixup = ''
          mv $out/bin/franklyn-sentinel $out/bin/franklyn
        '';
      });

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

    packages.franklyn-sentinel-deb = let
      desktopEntry = ''
        [Desktop Entry]
        Version=${project-version}
        Type=Application
        Name=Franklyn Sentinel
        GenericName=Screen Monitoring Client
        Comment=Streams student screen activity to the teacher during tests and exams
        Exec=/usr/bin/franklyn
        Icon=franklyn-sentinel
        Categories=Education;Network;
        Keywords=exam;monitor;screen;sentinel;franklyn;
        Terminal=false
        StartupNotify=true
      '';
    in
      pkgs.stdenv.mkDerivation {
        pname = "franklyn-sentinel";
        version = builtins.replaceStrings ["-"] ["~"] project-version;

        dontUnpack = true;

        src = ./debian;

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

          # icons
          mkdir -p $PKG_DIR/usr/share/icons/hicolor/
          cp -fr ${./debian}/icons/* $PKG_DIR/usr/share/icons/hicolor/

          # desktop entry
          mkdir -p "$PKG_DIR/usr/share/applications"
          echo "${desktopEntry}" >> "$PKG_DIR/usr/share/applications/franklyn-sentinel.desktop"

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
