{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    devShells.server = pkgs.mkShell {
      buildInputs = with pkgs; [
        maven
        quarkus
        jdk21_headless
        (pkgs.writeScriptBin "fr-server-build-clean" ''
          set -eu
          mvn clean package
        '')
        (pkgs.writeScriptBin "fr-server-verify" ''
          set -eu
          mvn clean verify
        '')
      ];
    };
  };
}
