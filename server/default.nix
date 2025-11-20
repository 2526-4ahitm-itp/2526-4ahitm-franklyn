{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    project-version,
    package-meta,
    ...
  }: let
    scripts = [
      (pkgs.writeScriptBin "fr-server-build-clean" ''
        set -eu
        mvn clean package
      '')
      (pkgs.writeScriptBin "fr-server-verify" ''
        set -eu
        mvn clean verify
      '')
    ];

    commonBuildInputs = with pkgs; [
      temurin-bin # java 21
      maven
    ];

    commonDevInputs = with pkgs; [
      quarkus
    ];
  in {
    devShells.server = pkgs.mkShell {
      nativeBuildInputs = commonBuildInputs ++ commonDevInputs;
    };

    packages.franklyn-server = pkgs.maven.buildMavenPackage rec {
      pname = "franklyn-server";
      version = project-version;

      src = ./.;

      mvnParameters = "-DskipTests";
      mvnHash = "sha256-UOqlVZYleLDH2fmiv8i7I/DLQnQTqT6xSXC+K/IIsHk=";

      installPhase = ''
        mkdir -p $out/lib
        ls -la target/
        cp target/franklyn-server-*-runner.jar $out/lib/franklyn-server-${project-version}.jar
      '';

      nativeBuildInputs = commonBuildInputs;

      meta = package-meta;
    };
  };
}
