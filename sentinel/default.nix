{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    pkgs-compat,
    pkgs-build,
    mkEnvHook,
    project-version,
    project-license-text,
    package-meta,
    maintainers,
    self',
    ...
  }: let
    isDarwin = pkgs.stdenv.isDarwin;

    # Runtime libraries linked into the binary and bundled into the
    # portable/dev outputs.
    rtPkgs =
      if isDarwin
      then pkgs
      else pkgs-compat;
    buildPkgs =
      if isDarwin
      then pkgs
      else pkgs-build;

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
        cargo build --release
      '')
      (pkgs.writeScriptBin "fr-sentinel-coverage" ''
        cargo tarpaulin --out xml --lib --all-features
      '')
    ];

    rustToolchain = buildPkgs.rust-bin.stable.latest.default.override {
      extensions = [
        "rust-src"
        "rust-analyzer"
        "clippy"
        "rustfmt"
      ];
    };

    commonNativeBuildInputs = with buildPkgs; [
      rustToolchain
      pkg-config
      clang
      patchelf
      cargo-bundle-licenses

      protoc-gen-prost
      protoc-gen-prost-crate
      buf
      protobuf
    ];

    commonBuildInputs =
      [buildPkgs.llvmPackages.libclang]
      ++ (with rtPkgs; [
        openssl_3

        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
      ]);

    linuxBuildInputs = with rtPkgs; [
      pipewire
      # xdg-desktop-portal
      # xdg-desktop-portal-gnome
    ];

    platformBuildInputs =
      rtPkgs.lib.optionals rtPkgs.stdenv.isLinux linuxBuildInputs
      ++ rtPkgs.lib.optionals rtPkgs.stdenv.isDarwin [
        rtPkgs.gst_all_1.gst-plugins-bad
      ];

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

    gstLicense = rtPkgs.stdenv.mkDerivation {
      name = "gstreamer-license";
      src = rtPkgs.gst_all_1.gstreamer.src;
      dontBuild = true;
      dontConfigure = true;
      installPhase = "cp COPYING $out";
    };

    craneLib = inputs.crane.mkLib pkgs;

    commonArgs = {
      pname = "franklyn-sentinel";
      version = project-version;
      src = craneLib.cleanCargoSource ./.;

      stdenv = _: buildPkgs.stdenv;

      nativeBuildInputs = commonNativeBuildInputs;

      buildInputs = commonBuildInputs ++ platformBuildInputs;

      LIBCLANG_PATH = "${buildPkgs.llvmPackages.libclang.lib}/lib";
      LICENSE_PATH = "${licenseFile}";
      VERSION_PATH = "${versionFile}";
      PROTOBUF_GEN_PATH = self'.packages.protobuf-gen;

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

    franklyn-sentinel-portable-darwin = pkgs.stdenv.mkDerivation {
      pname = "franklyn-sentinel-portable";
      version = project-version;

      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.cctools
        pkgs.gnutar
        pkgs.gzip
      ];

      buildPhase = ''
        source ${pkgs.darwin.signingUtils}

        mkdir -p bundle/bin bundle/lib/gstreamer-1.0 bundle/libexec
        cd bundle

        # Files to relocate, and the store path each was copied from (to
        # resolve @loader_path / @rpath references against).
        queue=()
        declare -A origin=()
        add() {
          cp -L "$2" "$1"
          chmod u+w "$1"
          queue+=("$1")
          origin["$1"]="$2"
        }

        add bin/franklyn ${self'.packages.franklyn-sentinel}/bin/franklyn
        add libexec/gst-plugin-scanner ${rtPkgs.gst_all_1.gstreamer.out}/libexec/gstreamer-1.0/gst-plugin-scanner
        for plugin in \
          ${rtPkgs.gst_all_1.gstreamer.out}/lib/gstreamer-1.0/libgstcoreelements.dylib \
          ${rtPkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0/libgstvideoconvertscale.dylib \
          ${rtPkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0/libgstvideorate.dylib \
          ${rtPkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0/libgstapp.dylib \
          ${rtPkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0/libgstjpeg.dylib \
          ${rtPkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0/libgstapplemedia.dylib
        do
          add "lib/gstreamer-1.0/$(basename "$plugin")" "$plugin"
        done

        # resolve DEP ORIGIN RPATH... — print the file DEP refers to, if found.
        resolve() {
          local dep="$1" from r
          from="$(dirname "$2")"
          shift 2
          case "$dep" in
            /nix/store/*) echo "$dep" ;;
            @loader_path/*) echo "$from/''${dep#@loader_path/}" ;;
            @rpath/*)
              for r in "$@"; do
                r="''${r/#@loader_path/$from}"
                if [ -e "$r/''${dep#@rpath/}" ]; then
                  echo "$r/''${dep#@rpath/}"
                  break
                fi
              done
              ;;
          esac
          return 0
        }

        i=0
        while [ "$i" -lt "''${#queue[@]}" ]; do
          f="''${queue[$i]}"
          i=$((i + 1))

          id="$(otool -D "$f" | tail -n +2)"
          mapfile -t deps < <(otool -L "$f" | tail -n +2 | awk '{print $1}')
          mapfile -t rpaths < <(otool -l "$f" | awk '/cmd LC_RPATH/ { getline; getline; print $2 }' | sort -u)

          for dep in "''${deps[@]}"; do
            if [ "$dep" = "$id" ]; then
              continue
            fi
            case "$dep" in
              /usr/lib/* | /System/*) continue ;;
            esac
            name="$(basename "$dep")"
            if [ ! -e "lib/$name" ]; then
              src="$(resolve "$dep" "''${origin[$f]}" "''${rpaths[@]}")"
              if [ -z "$src" ] || [ ! -e "$src" ]; then
                echo "cannot resolve $dep (needed by $f)" >&2
                exit 1
              fi
              add "lib/$name" "$src"
            fi
            install_name_tool -change "$dep" "@rpath/$name" "$f"
          done

          for r in "''${rpaths[@]}"; do
            install_name_tool -delete_rpath "$r" "$f"
          done
          case "$f" in
            bin/* | libexec/*)
              install_name_tool -add_rpath @executable_path/../lib "$f"
              ;;
            lib/gstreamer-1.0/*)
              install_name_tool -id "@rpath/$(basename "$f")" "$f"
              install_name_tool -add_rpath @loader_path/.. "$f"
              ;;
            lib/*)
              install_name_tool -id "@rpath/$(basename "$f")" "$f"
              install_name_tool -add_rpath @loader_path "$f"
              ;;
          esac
        done

        for f in "''${queue[@]}"; do
          if otool -L "$f" | grep -q /nix/store; then
            echo "$f still references /nix/store:" >&2
            otool -L "$f" >&2
            exit 1
          fi
          sign "$f"
        done

        cp ${gstLicense} GSTREAMER_LICENSE
        cp ${licenseFile} LICENSE
        cp ${./packaging/macos/README.portable.txt} README.txt
      '';

      installPhase = ''
        mkdir -p $out
        tar -czf $out/franklyn-sentinel-${project-version}-${system}-portable.tar.gz .
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
            value = "${buildPkgs.llvmPackages.libclang.lib}/lib";
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

    packages.franklyn-sentinel-portable =
      if isDarwin
      then franklyn-sentinel-portable-darwin
      else
        pkgs.stdenv.mkDerivation {
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
              [ -e "lib/$(basename "$libpath")" ] || cp "$libpath" lib/
            done

            chmod +w bin/franklyn
            patchelf --set-rpath '$ORIGIN/../lib' "bin/franklyn"

            cp ${rtPkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0/libgstvideoconvert.so lib/gstreamer-1.0
            cp ${rtPkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0/libgstvideoscale.so lib/gstreamer-1.0
            cp ${rtPkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0/libgstvideorate.so lib/gstreamer-1.0
            cp ${rtPkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0/libgstapp.so lib/gstreamer-1.0
            cp ${rtPkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0/libgstjpeg.so lib/gstreamer-1.0
            cp ${rtPkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0/libgstximagesrc.so lib/gstreamer-1.0
            cp ${rtPkgs.gst_all_1.gstreamer.out}/lib/gstreamer-1.0/libgstcoreelements.so lib/gstreamer-1.0
            cp ${rtPkgs.pipewire.lib}/lib/gstreamer-1.0/libgstpipewire.so lib/gstreamer-1.0

            mkdir -p libexec
            cp ${rtPkgs.gst_all_1.gstreamer.out}/libexec/gstreamer-1.0/gst-plugin-scanner libexec/

            # use unpatched binary to copy all depending libs
            ldd libexec/gst-plugin-scanner | grep "=> /nix/store" | awk '{print $3}' \
            | grep -vE 'libc\.so|libm\.so|libdl\.so|libpthread\.so|librt\.so|libresolv\.so|ld-linux|libgcc_s\.so|libstdc\+\+\.so' \
            | while read -r libpath; do
              echo "Copying $libpath to lib/"
              [ -e "lib/$(basename "$libpath")" ] || cp "$libpath" lib/
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

            for plugin in lib/gstreamer-1.0/*.so; do
              ldd $plugin | grep "=> /nix/store" | awk '{print $3}' \
              | grep -vE 'libc\.so|libm\.so|libdl\.so|libpthread\.so|librt\.so|libresolv\.so|ld-linux|libgcc_s\.so|libstdc\+\+\.so|libpipewire-.*\.so.*' \
              | while read -r libpath; do
                echo "Copying gstreamer $libpath to lib/"
                [ -e "lib/$(basename "$libpath")" ] || cp "$libpath" lib/
              done
            done

            find lib -type f -name '*.so*' | while read -r lib; do
              if file "$lib" | grep -q 'ELF'; then
                rel=$(realpath --relative-to="$(dirname "$lib")" lib)
                if [ "$rel" = "." ]; then rpath="\$ORIGIN"; else rpath="\$ORIGIN/$rel"; fi
                echo "Patching $lib (rpath=$rpath)"
                chmod +w "$lib"
                patchelf --set-rpath "$rpath" "$lib"
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
        Depends: libgstreamer1.0-0, gstreamer1.0-plugins-base, gstreamer1.0-plugins-good, gstreamer1.0-plugins-bad, gstreamer1.0-plugins-ugly, gstreamer1.0-libav, libssl3, libpipewire-0.3-0
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
