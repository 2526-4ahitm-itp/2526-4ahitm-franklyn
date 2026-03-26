{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    mkEnvHook,
    project-version,
    project-license-text,
    package-meta,
    maintainers,
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

    packages.franklyn-sentinel-rpm = let
      desktopEntry = pkgs.writeText "franklyn-sentinel.desktop" ''
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
        pname = "franklyn";
        version = project-version;

        dontUnpack = true;

        src = ./debian;

        nativeBuildInputs = with pkgs; [
          rpm
        ];

        buildPhase = ''
          set -e

          CHANGELOG_DATE="$(date '+%a %b %d %Y')"
          WORK_DIR="$PWD/work"
          STAGING_DIR="$WORK_DIR/staging"
          BUILDROOT="$WORK_DIR/buildroot"
          RPMBUILD_DIR="$WORK_DIR/rpmbuild"

          mkdir -p "$STAGING_DIR/usr/bin"
          mkdir -p "$STAGING_DIR/usr/share/icons/hicolor/"
          mkdir -p "$STAGING_DIR/usr/share/applications"
          mkdir -p "$BUILDROOT/usr/bin"
          mkdir -p "$BUILDROOT/usr/share/icons/hicolor/"
          mkdir -p "$BUILDROOT/usr/share/applications"
          mkdir -p "$RPMBUILD_DIR/BUILD"
          mkdir -p "$RPMBUILD_DIR/RPMS/x86_64"
          mkdir -p "$RPMBUILD_DIR/SOURCES"
          mkdir -p "$RPMBUILD_DIR/SPECS"
          mkdir -p "$RPMBUILD_DIR/SRPMS"

          cp ${self'.packages.franklyn-sentinel-patched}/bin/franklyn-sentinel-* "$STAGING_DIR/usr/bin/franklyn"
          cp -fr ${./debian}/icons/* "$STAGING_DIR/usr/share/icons/hicolor/"
          cp ${desktopEntry} "$STAGING_DIR/usr/share/applications/franklyn-sentinel.desktop"

          cp -r "$STAGING_DIR/usr" "$BUILDROOT/"

          tar -czf "$RPMBUILD_DIR/SOURCES/franklyn.tar.gz" -C "$STAGING_DIR" .

          cat > "$RPMBUILD_DIR/SPECS/franklyn.spec" << SPECEOF
Name:           franklyn
Version:        ''${version}
Release:        1
Summary:        Franklyn Sentinel Client
License:        Proprietary
Vendor:         Franklyn
URL:            https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn

%description
Franklyn Sentinel streams student screen activity to the teacher during tests and exams.

%prep
%setup -c -n %{name}

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/icons/hicolor/
mkdir -p %{buildroot}/usr/share/applications
cp -r usr/bin/* %{buildroot}/usr/bin/
cp -r usr/share/icons/* %{buildroot}/usr/share/icons/
cp usr/share/applications/* %{buildroot}/usr/share/applications/

%files
%defattr(-,root,root)
/usr/bin/franklyn
/usr/share/icons/hicolor/*
/usr/share/applications/franklyn-sentinel.desktop

%changelog
* $CHANGELOG_DATE ${maintainers.eldin.name} - ''${version}
- Initial package
SPECEOF

          HOME="$WORK_DIR" rpmbuild \
            --define "_topdir $RPMBUILD_DIR" \
            --define "_builddir $RPMBUILD_DIR/BUILD" \
            --define "_rpmdir $RPMBUILD_DIR/RPMS" \
            --define "_sourcedir $RPMBUILD_DIR/SOURCES" \
            --define "_specdir $RPMBUILD_DIR/SPECS" \
            --define "_srcrpmdir $RPMBUILD_DIR/SRPMS" \
            --buildroot "$BUILDROOT" \
            --short-circuit \
            --nodeps \
            -bb "$RPMBUILD_DIR/SPECS/franklyn.spec"
        '';

        installPhase = ''
          mkdir -p $out/lib
          mkdir -p $out/bin
          cp ${self'.packages.franklyn-sentinel-patched}/bin/franklyn-sentinel-* $out/bin
          find $PWD/work/rpmbuild/RPMS -name "*.rpm" -exec cp {} $out/lib/ \;
        '';

        meta = package-meta // {
          description = "Franklyn Sentinel Client";
        };
      };
  };
}
