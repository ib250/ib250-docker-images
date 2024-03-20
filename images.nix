{pkgs, ...}:
with pkgs.dockerTools; {
  devtools = buildLayeredImage {
    name = "devtools";
    tag = pkgs.lib.version;
    contents = with pkgs; [zoxide fzf eza scmpuff];
  };

  nix-basic = buildLayeredImage {
    name = "nix-basic";
    tag = pkgs.lib.version;
    contents = [pkgs.nix pkgs.stdenv];
  };
}
