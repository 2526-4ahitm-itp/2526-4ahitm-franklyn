{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    pkgs-unstable,
    mkEnvHook,
    ...
  }: let
    scripts = [
      (pkgs.writeScriptBin "fr-hugo-build" ''
        set -eu
        hugo --gc --minify "$@"
      '')
    ];
  in {
    devShells.hugo = pkgs.mkShell {
      name = "Franklyn Hugo DevShell";
      packages = with pkgs;
        [
          pkgs-unstable.hugo
          go_1_26
          asciidoctor
          git
        ]
        ++ scripts;
      shellHook = ''
        ${mkEnvHook [
          {
            name = "HUGO_GITHUB_PROJECT_URL";
            value = "https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn";
          }
        ]}
      '';
    };
  };
}
