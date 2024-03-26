let
  nixpkgs-url = "https://github.com/NixOS/nixpkgs/archive/ada65bada18e2ab9544aa35488b41631a6da2bda.tar.gz";
  pkgs = import (fetchTarball nixpkgs-url) {};
in {
  devtools = pkgs.buildEnv {
    name = "devtools";
    paths = with pkgs; [
      zoxide
      fzf
      fzf-zsh
      fzf-git-sh
      eza
      bat
      scmpuff
      zsh-fast-syntax-highlighting
    ];
  };

  inherit (pkgs) duckdb;

  inherit (pkgs) goose;

  golang = pkgs.buildEnv {
    name = "golang";
    paths = with pkgs; [go_1_22 gopls];
  };

  neovim-flake = pkgs.buildEnv {
    name = "neovim-flake";
    paths = let
      inherit (pkgs) system;
      flake = builtins.getFlake "github:ib250/neovim-flake";
    in [flake.packages.${system}.default];
  };

  rust = let
    fenix-url = "https://github.com/nix-community/fenix/archive/85f4139f3c092cf4afd9f9906d7ed218ef262c97.tar.gz";
    fenix = import (fetchTarball fenix-url) {};
  in
    pkgs.buildEnv {
      name = "fenix-rust";
      paths = with pkgs; [
        fenix.minimal.toolchain
        rust-analyzer
      ];
    };
}
