from nixos/nix:latest as build

workdir work
copy nix.conf nix.conf
env NIX_CONF_DIR=/work
copy default.nix .
copy flake.nix .
copy flake.lock .
copy builder.sh .

arg ATTRS
run builder.sh ${ATTRS}
