{
  pkgs,
  architecture,
  ...
}:
with pkgs.dockerTools; {
  devtools = buildLayeredImage {
    name = "devtools";
    tag = pkgs.lib.version;
    contents = with pkgs; [
      zoxide
      fzf
      fzf-zsh
      fzf-git-sh
      eza
      bat
      scmpuff
      zsh-fast-syntax-highlighting
    ];
    inherit architecture;
  };

  nix-basic = buildLayeredImage {
    name = "nix-basic";
    tag = pkgs.lib.version;
    contents = [pkgs.nix pkgs.stdenv];
    inherit architecture;
  };

  duckdb = buildLayeredImage {
    name = "duckdb";
    tag = pkgs.lib.version;
    contents = [pkgs.duckdb];
    inherit architecture;
  };

  rust = buildLayeredImage {
    name = "rust";
    tag = pkgs.lib.version;
    contents = [
      (pkgs.fenix.complete.withComponents [
        "cargo"
        "clippy"
        "rust-src"
        "rustc"
        "rustfmt"
      ])
    ];
    inherit architecture;
  };

  nvim-treesitter = buildLayeredImage {
    name = "nvim-treesitter";
    tag = pkgs.lib.version;
    contents = [
      pkgs.vimPlugins.nvim-treesitter.withAllGrammars
    ];
    inherit architecture;
  };
}
