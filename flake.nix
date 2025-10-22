{
  description = "Franklyn all deps flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [(import rust-overlay)];
      pkgs = import nixpkgs {
        inherit system overlays;
      };

      rust = pkgs.rust-bin.stable.latest.default.override {
        extensions = [
          "rust-src"
          "rust-analyzer"
          "clippy"
          "rustfmt"
        ];
      };

      server-pkgs = with pkgs; [
        jdk17_headless
        maven
        quarkus
      ];

      docs-pkgs = with pkgs; [
        hugo
        go
        asciidoctor
      ];

      proctor-pkgs = with pkgs; [
        bun
      ];

      sentinel-pkgs = with pkgs;
        [
          # rust
          rust
          xorg.libxcb

          # Cargo tools
          cargo
          cargo-bloat # Analyze binary size
          cargo-edit # Add/remove dependencies from CLI
          cargo-outdated # Check for outdated dependencies
          cargo-udeps # Find unused dependencies
          cargo-watch # Auto-rebuild on file changes

          # Additional useful tools
          pkg-config
          openssl
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
          pkgs.darwin.apple_sdk.frameworks.Security
          pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
        ];
    in {
      devShells = {
        default = pkgs.mkShell {
          buildInputs = server-pkgs ++ docs-pkgs ++ proctor-pkgs ++ sentinel-pkgs;

          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.llvmPackages.clang.version}/include";
        };

        sentinel = pkgs.mkShell {
          buildInputs = sentinel-pkgs;
        };

        proctor = pkgs.mkShell {
          buildInputs = proctor-pkgs;
        };

        docs = pkgs.mkShell {
          buildInputs = docs-pkgs;
        };
      };
    });
}
