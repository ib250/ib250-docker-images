
let
  nixpkgs-url = "https://github.com/NixOS/nixpkgs/archive/ada65bada18e2ab9544aa35488b41631a6da2bda.tar.gz";
  pkgs = import (fetchTarball nixpkgs-url) {};
in pkgs.buildEnv {
  name   = "nix-basic";
  paths  = with pkgs; [stdenv zsh lf neovim];
}
