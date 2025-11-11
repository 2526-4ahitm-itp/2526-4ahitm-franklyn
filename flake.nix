{
  description = "Franklyn all deps flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} (
      top @ {
        config,
        withSystem,
        moduleWithSystem,
        ...
      }: {
        imports = [
          ./hugo
          ./sentinel
          ./proctor
          ./server
        ];
        flake = {
        };
        systems = [
          "x86_64-linux"
          "aarch64-darwin"
          "aarch64-linux"
        ];
        perSystem = {
          config,
          system,
          pkgs,
          self',
          ...
        }: {
          devShells.default = pkgs.mkShell {
            inputsFrom = [
              self'.devShells.sentinel
              self'.devShells.hugo
              self'.devShells.proctor
              self'.devShells.server
            ];
          };
        };
      }
    );
}
