{
  description = "Asterion archive";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.inotify-tools
            pkgs.beam.packages.erlang_26.elixir_1_16
            pkgs.zip
          ];

          env = {
            ERL_AFLAGS = "+pc unicode -kernel shell_history enabled";
            ELIXIR_ERL_OPTIONS = "+sssdio 128";
          };
        };
      });
}

