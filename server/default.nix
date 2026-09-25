{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    mkEnvHook,
    project-version,
    package-meta,
    ...
  }: let
    scripts = [
      (pkgs.writeScriptBin "fr-server-build-clean" ''
        set -eu
        mvn clean package
      '')
      (pkgs.writeScriptBin "fr-server-pr-check" ''
        set -eu
        mvn clean checkstyle:check
        mvn clean --batch-mode verify \
          -DskipITs=false \
          -Dquarkus.package.write-transformed-bytecode-to-build-output=true
      '')
    ];

    commonBuildInputs = with pkgs; [
      javaPackages.compiler.temurin-bin.jdk-25
      maven
      ffmpeg-headless
    ];

    commonDevInputs = with pkgs; [
      quarkus
    ];

    # The "# darwin" and "# linux" comments below are anchors for scripts/update-mvn-hash.sh.
    # Keep them; if you change these lines, update that script too.
    mvnHash =
      if builtins.getEnv "FRANKLYN_USE_FAKE_MVN_HASH" != ""
      then pkgs.lib.fakeHash
      else if pkgs.stdenv.isDarwin
      then "sha256-VgfxcOBgpDTkQ5meCkEaUOBuYCdPIckYUAvZoHoB3bw=" # darwin
      else "sha256-w6CDYTu7eCw3uDulXqHVDw2mUQV1g4quwsChuL71QCU="; # linux
  in {
    devShells.server = pkgs.mkShell {
      name = "Franklyn Server DevShell";
      packages = commonBuildInputs ++ commonDevInputs ++ scripts;
    };

    packages.franklyn-server = pkgs.maven.buildMavenPackage rec {
      pname = "franklyn-server";
      version = project-version;

      src = ./.;

      mvnParameters = "-DskipTests -Drevision=${project-version}";
      inherit mvnHash;

      installPhase = ''
        mkdir -p $out/lib
        cp target/$pname-*-runner.jar $out/lib/$pname-$version.jar
      '';

      nativeBuildInputs = commonBuildInputs;

      meta = package-meta;
    };
  };
}
