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
        mvn clean --batch-mode verify \
          -DskipITs=false \
          -Dquarkus.package.write-transformed-bytecode-to-build-output=true
      '')
    ];

    commonBuildInputs = with pkgs; [
      javaPackages.compiler.temurin-bin.jdk-25
      maven
    ];

    commonDevInputs = with pkgs; [
      quarkus
      sqlc
    ];
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
      mvnHash =
        if builtins.getEnv "FRANKLYN_USE_FAKE_MVN_HASH" != ""
        then pkgs.lib.fakeHash
        else if pkgs.stdenv.isDarwin
        then "sha256-uuS2+A53CE/KTHUI0u1uFh8fI26o0MNLb0Z3iy2NYio=" # darwin
        else "sha256-C+Uo4IzVQfs7rGqRIgOI/PivuK7PHYmRaSL+RrGdOac="; # linux

      installPhase = ''
        mkdir -p $out/lib
        cp target/$pname-*-runner.jar $out/lib/$pname-$version.jar
      '';

      nativeBuildInputs = commonBuildInputs;

      meta = package-meta;
    };
  };
}
