{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    mkEnvHook,
    project-version,
    package-meta,
    ...
  }: let
    commonBuildInputs = with pkgs; [
      bun
      nodejs_22
    ];

    commonDevInputs = [];
  in {
    devShells.proctor = pkgs.mkShell {
      name = "Franklyn Proctor DevShell";
      packages =
        commonBuildInputs
        ++ commonDevInputs;
      shellHook = ''
        fr-proctor-pr-check() {
          set -eu
          bun install
          bun run type-check
          bun run lint:check -- --output-file eslint_report.json --format json
          bun run build
        }

        fr-proctor-build() {
          set -eu
          bun install
          bun run build "$@"
        }
      '';
    };
  };
}
