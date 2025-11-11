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
        (pkgs.writeScriptBin "fr-server-format" ''
          set -eu
          mvn ktlint:format
        '')
        (pkgs.writeScriptBin "fr-server-check" ''
          set -eu
          mvn ktlint:check
        '')
        (pkgs.writeScriptBin "fr-server-report" ''
          set -eu
          mvn validate
        '')
        (pkgs.writeScriptBin "fr-server-verify" ''
          set -eu
          mvn verify
        '')
      ];
    };
  };
}
