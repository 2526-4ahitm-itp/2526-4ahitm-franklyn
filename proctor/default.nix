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
          bun run lint -- --output-file eslint_report.json --format json
        '')
      ];
    };
  };
}
