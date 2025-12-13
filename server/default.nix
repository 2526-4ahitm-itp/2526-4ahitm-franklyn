{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    mkEnvHook,
    project-version,
    package-meta,
    ...
  }: let
    commonBuildInputs = with pkgs; [
      javaPackages.compiler.temurin-bin.jdk-25
      maven
    ];

    commonDevInputs = with pkgs; [
      quarkus
    ];
  in {
    devShells.server = pkgs.mkShell {
      name = "Franklyn Server DevShell";
      packages =
        commonBuildInputs
        ++ commonDevInputs;
      shellHook = ''
        fr-server-build-clean() {
            set -eu
            mvn clean package
        }

        fr-server-verify() {
            set -eu
            mvn clean verify
        }
      '';
    };

    packages.franklyn-server = pkgs.maven.buildMavenPackage rec {
      pname = "franklyn-server";
      version = project-version;

      src = ./.;

      mvnParameters = "-DskipTests";
      mvnHash = "sha256-yHvMsTyW10c5nH2zh6jIeCHrmZSDIjVzwxXpkgqrJWQ=";

      installPhase = ''
        mkdir -p $out/lib
        cp target/$pname-*-runner.jar $out/lib/$pname-$version.jar
      '';

      nativeBuildInputs = commonBuildInputs;

      meta = package-meta;
    };
  };
}
