{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    mkEnvHook,
    ...
  }: {
    devShells.hugo = pkgs.mkShell {
      name = "Franklyn Hugo DevShell";
      packages = with pkgs; [
        hugo
        go
        asciidoctor
        git
      ];
      shellHook = ''
        ${mkEnvHook [
          {
            name = "HUGO_GITHUB_PROJECT_URL";
            value = "https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn";
          }
        ]}
        fr-hugo-build() {
          set -eu
          hugo --gc --minify "$@"
        }
      '';
    };
  };
}
