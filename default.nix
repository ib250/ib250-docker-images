{
  pkgs,
  fenix,
  neovim-flake,
  ...
}: let
  buildEnv' = args:
    pkgs.buildEnv (args // {extraOutputsToInstall = ["doc" "man" "lib"];});
in {
  devtools = buildEnv' {
    name = "devtools";
    paths = with pkgs; [
      bat
      eza
      ripgrep
      fd
      fzf
      fzf-zsh
      fzf-git-sh
      neovim-flake
      scmpuff
      zsh-fast-syntax-highlighting
      zoxide
    ];
  };

  duckdb = buildEnv' {
    name = "duckdb";
    paths = [pkgs.duckdb];
  };

  goose = buildEnv' {
    name = "goose";
    paths = [pkgs.goose];
  };

  golang = buildEnv' {
    name = "golang";
    paths = with pkgs; [go_1_22 gopls];
  };

  rust = buildEnv' {
    name = "fenix-rust";
    paths = [
      fenix.complete.toolchain
    ];
  };
}
