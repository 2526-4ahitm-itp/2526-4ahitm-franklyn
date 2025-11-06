{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    devShells.proctor = pkgs.mkShell {
      buildInputs = with pkgs; [
        bun
      ];
    };
  };
}
