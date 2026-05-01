{
  description = "Franklyn all deps flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-parts.url = "github:hercules-ci/flake-parts";
    crane.url = "github:ipetkov/crane";
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} (
      {lib, ...}: {
        imports = [
          ./hugo
          ./sentinel
          ./proctor
          ./server
          ./ios
        ];
        flake = {
        };
        systems = [
          "x86_64-linux"
          "aarch64-darwin"
          "aarch64-linux"
        ];
        perSystem = {
          system,
          pkgs,
          pkgs-unstable,
          self',
          ...
        }: let
          # globals
          project-version = lib.strings.removeSuffix "\n" (builtins.readFile ./VERSION);
          project-license-text = builtins.readFile ./LICENSE;

          maintainers.jakob = {
            name = "Jakob Huemer-Fistelberger";
            github = "JakobHuemer";
          };

          package-meta = {
            homepage = "https://2526-4ahitm-itp.github.io/2526-4ahitm-franklyn/";
            license = pkgs.lib.licenses.mit;
            email = "franklyn@htl-leonding.ac.at";
          };
        in {
          _module.args = {
            inherit
              project-version
              project-license-text
              package-meta
              maintainers
              ;

            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                inputs.rust-overlay.overlays.default
              ];
            };

            pkgs-unstable = import inputs.nixpkgs-unstable {
              inherit system;
            };

            mkEnvHook = envList: pkgs.lib.concatStringsSep "\n" (map (env: "export ${env.name}=${env.value}") envList);
          };

          devShells.ci = pkgs.mkShell {
            packages = [
              pkgs.gh
              pkgs.jq
              pkgs.semver-tool
            ];
          };

          packages.protobuf-gen = pkgs.stdenv.mkDerivation {
            name = "protobuf-gen";

            version = "0.1.0";

            src = pkgs.nix-gitignore.gitignoreSource [] ./protobuf;

            nativeBuildInputs = with pkgs; [
              buf

              protoc-gen-prost
              protoc-gen-prost-crate
              protoc-gen-es
            ];

            buildPhase = ''
              export HOME=$TMP
              buf generate .
            '';

            installPhase = ''
              mkdir $out/
              cp -r gen/. $out/
            '';
          };

          devShells.default = pkgs.mkShell {
            inputsFrom =
              [
                self'.devShells.sentinel
                self'.devShells.server
                self'.devShells.hugo
                self'.devShells.proctor
                self'.devShells.ci
              ]
              ++ pkgs.lib.optional pkgs.stdenv.isDarwin self'.devShells.ios;

            packages = with pkgs; [
              protobuf
              buf
              tokei
              pkgs-unstable.bruno
            ];
          };
        };
      }
    );
}
