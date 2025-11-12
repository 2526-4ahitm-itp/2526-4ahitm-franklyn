{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    devShells.proctor = pkgs.mkShell {
      buildInputs = with pkgs; [
        bun
        (pkgs.writeScriptBin "fr-proctor-pr-check" ''
          set -eu
          bun install
          bun run lint:check -- --output-file eslint_report.json --format json
        '')
      ];
    };
  };
}
