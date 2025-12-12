{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    ...
  }: {
    devshells.hugo = {
      devshell.name = "Franklyn Hugo DevShell";

      packages = with pkgs; [
        hugo
        go
        asciidoctor
        git
      ];

      commands = [
        {
          name = "fr-hugo-build";
          help = "Build Hugo site with GC + minify";
          command = ''
            set -eu
            hugo --gc --minify "$@"
          '';
          category = "build";
        }
      ];

      env = [
        {
          name = "HUGO_GITHUB_PROJECT_URL";
          value = "https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn";
        }
      ];
    };
  };
}
