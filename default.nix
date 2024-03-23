let
  pkgs = import (builtins.fetchTarball {
    name = "nixpkgs-unstable";
    url = "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz";
    sha256 = "sha256:0gdk1lbba8c88y2jj13m8nhzf9bds7f1gw4fhm89p2xz5zagxgiy";
  }) {};
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

  rust = let
    fenix = import (builtins.fetchTarball {
      name = "fenix-unstable";
      url = "https://github.com/nix-community/fenix/archive/main.tar.gz";
      sha256 = "sha256:1490vqc12xfvncw499k1wpns2zyk7rfsfsahm1b85npiniina9si";
    }) {};
  in
    pkgs.buildEnv {
      name = "fenix-complete-rust";
      paths = [
        (fenix.complete.withComponents [
          "cargo"
          "clippy"
          "rust-src"
          "rustc"
          "rustfmt"
        ])
        fenix.rust-analyzer
      ];
    };
}
