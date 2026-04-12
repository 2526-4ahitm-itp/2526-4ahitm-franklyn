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

      patchelf
    ];

    gstLicense = pkgs.stdenv.mkDerivation {
      name = "gstreamer-license";
      src = pkgs.gst_all_1.gstreamer.src;
      dontBuild = true;
      dontConfigure = true;
      installPhase = "cp COPYING $out";
    };

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

      cargoExtraArgs = "--features prod";

      meta = package-meta;
    };

    cargoArtifacts = craneLib.buildDepsOnly commonArgs;

    commonSrc =
      commonArgs
      // {
        inherit cargoArtifacts;
      };

    franklyn-sentinel-dist = pkgs.stdenv.mkDerivation {
      pname = "franklyn-sentinel-dist";
      version = project-version;
      dontUnpack = true;
      nativeBuildInputs = [pkgs.patchelf];
      installPhase = ''
        mkdir -p $out/bin

        cp ${self'.packages.franklyn-sentinel}/bin/franklyn $out/bin/franklyn
        bin="$out/bin/franklyn"
        chmod +w "$bin"

        interpreter="${
          if system == "x86_64-linux"
          then "/lib64/ld-linux-x86-64.so.2"
          else if system == "aarch64-linux"
          then "/lib/ld-linux-aarch64.so.1"
          else ""
        }"
        if [ -n "$interpreter" ]; then
          patchelf --remove-rpath --set-interpreter "$interpreter" "$bin"
        fi

        mkdir $out/share/applications -p
        mkdir $out/share/icons/hicolor -p

        cp -r ${./resources}/icons/* $out/share/icons/hicolor

        cp ${gstLicense} $out/GSTREAMER_LICENSE
        cp ${licenseFile} $out/LICENSE
      '';
    };

    desktopEntry = pkgs.replaceVars ./resources/franklyn-sentinel.desktop {
      VERSION = project-version;
      BINARY_PATH = "/usr/bin/franklyn";
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

    packages.franklyn-sentinel-coverage = craneLib.cargoTarpaulin (commonSrc
      // {
        cargoTarpaulinExtraArgs = "--out xml --all-features";
      });

    packages.franklyn-sentinel-fmt = craneLib.cargoFmt (commonSrc
      // {
        cargoExtraArgs = "";
      });

    packages.franklyn-sentinel-clippy = craneLib.cargoClippy (commonSrc
      // {
        cargoClippyExtraArgs = "--all-targets --all-features --message-format=short";
      });

    packages.franklyn-sentinel-deny = craneLib.cargoDeny (commonSrc
      // {
        cargoExtraArgs = "";
      });

    packages.franklyn-sentinel-check = pkgs.stdenv.mkDerivation {
      name = "franklyn-sentinel-check";

      dontUnpack = true;

      installPhase = ''
        mkdir $out/deny -p
        mkdir $out/fmt
        mkdir $out/clippy
        mkdir $out/coverage
        cp -r ${self'.packages.franklyn-sentinel-deny}/. $out/deny
        cp -r ${self'.packages.franklyn-sentinel-fmt}/. $out/fmt
        cp -r ${self'.packages.franklyn-sentinel-clippy}/. $out/clippy
        cp -r ${self'.packages.franklyn-sentinel-coverage}/. $out/coverage
      '';
    };

    packages.franklyn-sentinel = craneLib.buildPackage (
      commonSrc
      // {
        postFixup = ''
          mv $out/bin/franklyn-sentinel $out/bin/franklyn
        '';
      }
    );

    packages.franklyn-sentinel-dist = pkgs.stdenv.mkDerivation {
      pname = "franklyn-sentinel-dist";
      version = project-version;
      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.gnutar
        pkgs.zstd
      ];

      installPhase = ''
        mkdir $out -p
        tar -C ${franklyn-sentinel-dist} --zstd -cf $out/franklyn-sentinel-${project-version}-${system}-dist.tar.zst .
      '';
    };

    packages.franklyn-sentinel-portable = pkgs.stdenv.mkDerivation {
      pname = "franklyn-sentinel-portable";
      version = project-version;

      src = franklyn-sentinel-dist;

      nativeBuildInputs =
        [
          pkgs.gnutar
          pkgs.zstd
          pkgs.patchelf
        ]
        ++ commonNativeBuildInputs
        ++ commonBuildInputs
        ++ platformBuildInputs;

      buildPhase = ''
        mkdir -p lib/gstreamer-1.0

        # use unpatched binary to copy all depending libs
        ldd ${self'.packages.franklyn-sentinel}/bin/franklyn | grep "=> /nix/store" | awk '{print $3}' \
        | grep -vE 'libc\.so|libm\.so|libdl\.so|libpthread\.so|librt\.so|libresolv\.so|ld-linux|libgcc_s\.so|libstdc\+\+\.so' \
        | while read -r libpath; do
          echo "Copying $libpath to lib/"
          cp -n "$libpath" lib/
        done

        patchelf --set-rpath '$ORIGIN/../lib' "bin/franklyn"

        cp ${pkgs.gst_all_1.gst-plugins-base}/lib/libgstapp-1.0.so lib/gstreamer-1.0
        cp ${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0/libgstvideoconvertscale.so lib/gstreamer-1.0
        cp ${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0/libgstvideorate.so lib/gstreamer-1.0
        cp ${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0/libgstapp.so lib/gstreamer-1.0
        cp ${pkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0/libgstjpeg.so lib/gstreamer-1.0
        cp ${pkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0/libgstximagesrc.so lib/gstreamer-1.0
        cp ${pkgs.gst_all_1.gstreamer.out}/lib/gstreamer-1.0/libgstcoreelements.so lib/gstreamer-1.0
        cp ${pkgs.pipewire}/lib/gstreamer-1.0/libgstpipewire.so lib/gstreamer-1.0

        mkdir -p libexec
        cp ${pkgs.gst_all_1.gstreamer.out}/libexec/gstreamer-1.0/gst-plugin-scanner libexec/

        # use unpatched binary to copy all depending libs
        ldd libexec/gst-plugin-scanner | grep "=> /nix/store" | awk '{print $3}' \
        | grep -vE 'libc\.so|libm\.so|libdl\.so|libpthread\.so|librt\.so|libresolv\.so|ld-linux|libgcc_s\.so|libstdc\+\+\.so' \
        | while read -r libpath; do
          echo "Copying $libpath to lib/"
          cp -n "$libpath" lib/
        done

        chmod +w libexec/*
        interpreter="${
          if system == "x86_64-linux"
          then "/lib64/ld-linux-x86-64.so.2"
          else if system == "aarch64-linux"
          then "/lib/ld-linux-aarch64.so.1"
          else ""
        }"
        if [ -n "$interpreter" ]; then
          patchelf --set-rpath '$ORIGIN/../lib' --set-interpreter "$interpreter" "libexec/gst-plugin-scanner"
        fi

        chmod +w lib/gstreamer-1.0/*.so

        for plugin in lib/gstreamer-1.0/*.so; do \
          ldd $plugin | grep "=> /nix/store" | awk '{print $3}' \
          | grep -vE 'libc\.so|libm\.so|libdl\.so|libpthread\.so|librt\.so|libresolv\.so|ld-linux|libgcc_s\.so|libstdc\+\+\.so|libpipewire-.*\.so.*' \
          | while read -r libpath; do
            echo "Copying gstreamer $libpath to lib/"
            cp -n "$libpath" lib/
          done
          patchelf --set-rpath '$ORIGIN/..' "$plugin"
        done

        find lib -type f -name '*.so*' | while read -r lib; do
          if file "$lib" | grep -q 'ELF'; then
            dir=$(dirname "$lib")

            rel=$(realpath --relative-to="$dir" lib)

            echo "Patching $lib (rpath=\$ORIGIN/$rel)"
            chmod +w "$lib"
            patchelf --set-rpath "\$ORIGIN/$rel" "$lib"
          else
            echo "Skipping non-ELF: $lib"
          fi
        done

        cp ${./resources/README.portable.txt} README.txt
      '';

      installPhase = ''
        mkdir -p $out
        tar --zstd -cf $out/franklyn-sentinel-${project-version}-${system}-portable.tar.zst .
      '';
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

        cp ${franklyn-sentinel-dist}/bin/franklyn $PKG_DIR/usr/bin/

        mkdir -p $PKG_DIR/usr/share/icons/hicolor/
        cp -r ${franklyn-sentinel-dist}/share/icons/* $PKG_DIR/usr/share/icons

        mkdir -p "$PKG_DIR/usr/share/applications"
        cp ${desktopEntry} "$PKG_DIR/usr/share/applications/franklyn-sentinel.desktop"

        cat <<EOF > $PKG_DIR/DEBIAN/control
        Package: franklyn-sentinel
        Version: $version
        Maintainer: ${maintainers.jakob.name} <${package-meta.email}>
        Architecture: ''${ARCHITECTURE}
        Depends: libgstreamer1.0-0, gstreamer1.0-plugins-base, gstreamer1.0-plugins-good, gstreamer1.0-plugins-bad, gstreamer1.0-plugins-ugly, gstreamer1.0-libav
        Description: Franklyn Client
        EOF

        dpkg-deb --build --root-owner-group $PKG_DIR
      '';

      installPhase = ''
        mkdir $out
        cp $OUT_DIR/franklyn-sentinel*.deb $out/
      '';

      meta = package-meta;
    };
  };
}
