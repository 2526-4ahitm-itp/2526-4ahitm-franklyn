{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    devShells.server = let
      build-server = pkgs.writeScriptBin "build-server" ''
        set -eu
        cd server
        mvn clean package
      '';
    in
      pkgs.mkShell {
        buildInputs = with pkgs;
          [
            maven
            quarkus
            jdk17_headless
          ]
          ++ [build-server];
      };
  };
}
