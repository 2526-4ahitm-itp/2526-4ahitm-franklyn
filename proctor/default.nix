{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    project-version,
    package-meta,
    ...
  }: let
    scripts = [
      (pkgs.writeScriptBin "fr-proctor-pr-check" ''
        set -eu
        bun install
        bun run type-check
        bun run lint:check -- --output-file eslint_report.json --format json
        bun run build
      '')
      (pkgs.writeScriptBin "fr-proctor-build" ''
        set -eu
        bun install
        bun run build "$@"
      '')
    ];

    commonBuildInputs = with pkgs; [
      bun
      nodejs_22
    ];

    commonDevInputs = [];
  in {
    devShells.proctor = pkgs.mkShell {
      buildInputs =
        commonBuildInputs
        ++ commonDevInputs
        ++ scripts;
    };
  };
}
