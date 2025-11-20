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
      jre21_minimal
      maven
    ];

    commonDevInputs = with pkgs; [
      jdk21_headless
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
        ls target -la
        echo "version: '${project-version}'end"
        cp target/franklyn-server-*.jar $out/lib/franklyn-server-${project-version}.jar
      '';

      nativeBuildInputs = commonBuildInputs;

      meta = package-meta;
    };
  };
}
