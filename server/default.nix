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
      (pkgs.writeScriptBin "fr-server-verify" ''
        set -eu
        mvn clean verify
      '')
    ];

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
        ++ commonDevInputs
        ++ scripts;
    };

    packages.franklyn-server = pkgs.maven.buildMavenPackage rec {
      pname = "franklyn-server";
      version = project-version;

      src = ./.;

      mvnParameters = "-DskipTests";
      mvnHash =
        if pkgs.stdenv.isDarwin
        then "sha256-Yb4I/Hti6DYBpEwuW63v7KoDRFR8hVpj7A5sBDZfrrs="
        else "sha256-xlruMfW2il0zmoK1ywkXs5hLvC6mpl2O0+pyIjFkJr8=";

      installPhase = ''
        mkdir -p $out/lib
        cp target/$pname-*-runner.jar $out/lib/$pname-$version.jar
      '';

      nativeBuildInputs = commonBuildInputs;

      meta = package-meta;
    };
  };
}
