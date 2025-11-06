{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    ...
  }: let
    build-hugo = pkgs.writeScriptBin "build-hugo" ''
      cd hugo
      hugo --gc --minify --baseURL $HUGO_BASE_URL --cacheDir $HUGO_CACHE_DIR
    '';
  in {
    devShells.hugo = pkgs.mkShell {
      nativeBuildInputs = with pkgs;
        [
          hugo
          go
          asciidoctor
          git
        ]
        ++ [build-hugo];
    };
  };
}
