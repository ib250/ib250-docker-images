from nixos/nix:latest

workdir /home/bootstrap
copy nix-basic.nix .
copy nix.conf .
env NIX_CONF_DIR=/home/bootstrap
run nix profile install -f nix-basic.nix

expose 22
