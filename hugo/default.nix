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

      shellHook = ''
        # !!! this should be the only point where the github url is referenced on the entire website
        # !!! changing this to the new repo should make everything work again
        export HUGO_GITHUB_PROJECT_URL="https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn"
      '';
    };
  };
}
