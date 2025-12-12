{
  description = "Franklyn all deps flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
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
          inputs.devshell.flakeModule
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
          };

          devshells.default = let
            inherit (lib) concatLists unique;
            devs = config.devshells;

            # avoid path collisions by dropping all prebuilt menus; devshell adds one itself
            collectedPackages = let
              merged = concatLists [
                (devs.server.packages or [])
                (devs.proctor.packages or [])
                (devs.hugo.packages or [])
                (devs.sentinel.packages or [])
              ];

              isMenu = p:
                let n = (p.pname or p.name or ""); in lib.hasPrefix "menu-" n || n == "menu";

              filtered = lib.filter (p: !isMenu p) merged;

              dedupByDrvPath = lib.foldl' (acc: p:
                if lib.any (x: x == p) acc then acc else acc ++ [p]
              ) [];
            in dedupByDrvPath filtered;

            collectedCommands = let
              merged = concatLists [
                (devs.server.commands or [])
                (devs.proctor.commands or [])
                (devs.hugo.commands or [])
                (devs.sentinel.commands or [])
              ];

              dedupByName = lib.foldl' (acc: c:
                if lib.any (x: x.name == c.name) acc then acc else acc ++ [c]
              ) [];
            in dedupByName (lib.filter (c: c.name != "menu") merged);

            collectedEnv = [];
          in {
            devshell.name = "Franklyn All-in-one DevShell";
            packages = collectedPackages;
            commands = collectedCommands;
            env = collectedEnv;
          };
        };
      }
    );
}
