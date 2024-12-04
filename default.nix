{
  pkgs,
  fenix,
  neovim-flake,
  inputs,
  ...
}: let
  buildEnv' = args:
    pkgs.buildEnv (args // {extraOutputsToInstall = ["doc" "man" "lib"];});
in {
  devtools = buildEnv' {
    name = "devtools";
    paths = with inputs.neovim-flake.nixpkgs; [
      bat
      eza
      zsh-fast-syntax-highlighting
      zoxide
      # fd fzf ripgrep already provided by neovim-flake.nvim-overlay-env
      neovim-flake.nvim-overlay-env
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
