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
        if builtins.getEnv "FRANKLYN_USE_FAKE_MVN_HASH" != ""
        then pkgs.lib.fakeHash
        else if pkgs.stdenv.isDarwin
        then "sha256-j8XIEfYCZtO+PZMFp2uxMCTeZghQB/myRJ2UsqMVtjM=" # darwin
        else "sha256-7yCEyY+us+kOoIVY2FKAP4kHmWUdUhiFbSUNWlFjtDk="; # linux

      installPhase = ''
        mkdir -p $out/lib
        cp target/$pname-*-runner.jar $out/lib/$pname-$version.jar
      '';

      nativeBuildInputs = commonBuildInputs;

      meta = package-meta;
    };
  };
}
