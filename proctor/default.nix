{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    project-version,
    package-meta,
    ...
  }: let
    scripts = [
      {
        name = "fr-proctor-pr-check";
        help = "Run Proctor type-check, lint and build";
        command = ''
          set -eu
          bun install
          bun run type-check
          bun run lint:check -- --output-file eslint_report.json --format json
          bun run build
        '';
        category = "ci";
      }
      {
        name = "fr-proctor-build";
        help = "Build Proctor app";
        command = ''
          set -eu
          bun install
          bun run build "$@"
        '';
        category = "build";
      }
    ];

    commonBuildInputs = with pkgs; [
      bun
      nodejs_22
    ];

    commonDevInputs = [];
  in {
    devshells.proctor = {
      devshell.name = "Franklyn Proctor DevShell";

      packages =
        commonBuildInputs
        ++ commonDevInputs;

      commands = scripts;
    };
  };
}
