{
  description = "Franklyn all deps flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} (
      top @ {
        config,
        withSystem,
        moduleWithSystem,
        lib,
        pkgs,
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
        }: let
          # globals
          project-version = lib.strings.removeSuffix "\n" (builtins.readFile ./VERSION);

          package-meta = {
            homepage = "https://2526-4ahitm-itp.github.io/2526-4ahitm-franklyn/";
            license = pkgs.lib.licenses.mit;
          };
        in {
          _module.args = {
            inherit project-version package-meta;

            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                inputs.rust-overlay.overlays.default
              ];
            };

            mkEnvHook = envList:
              pkgs.lib.concatStringsSep "\n" (map (env: "export ${env.name}=${env.value}") envList);
          };

          devShells.default = pkgs.mkShell {
            inputsFrom = [
              self'.devShells.sentinel
              self'.devShells.server
              self'.devShells.hugo
              self'.devShells.proctor
            ];

            packages = with pkgs; [
              cloc
              gh
              jq
              tokei
            ];
          };
        };
      }
    );
}
