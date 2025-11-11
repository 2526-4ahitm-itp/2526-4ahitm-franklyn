{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    ...
  }: {
    devShells.hugo = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
        hugo
        go
        asciidoctor
        git
        (pkgs.writeScriptBin "fr-hugo-build" ''
          set -eu
          hugo --gc --minify "$@"
        '')
      ];
    };
  };
}
