{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    project-version,
    package-meta,
    ...
  }: let
    scripts = [
      {
        name = "fr-server-build-clean";
        help = "Clean and package the server";
        command = ''
          set -eu
          mvn clean package
        '';
        category = "build";
      }
      {
        name = "fr-server-verify";
        help = "Run Maven verify for server";
        command = ''
          set -eu
          mvn clean verify
        '';
        category = "ci";
      }
    ];

    commonBuildInputs = with pkgs; [
      javaPackages.compiler.temurin-bin.jdk-25
      maven
    ];

    commonDevInputs = with pkgs; [
      quarkus
    ];
  in {
    devshells.server = {
      devshell.name = "Franklyn Server DevShell";

      packages =
        commonBuildInputs
        ++ commonDevInputs;

      commands = scripts;
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
