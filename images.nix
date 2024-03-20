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
      zsh-syntax-highlighting
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
}
