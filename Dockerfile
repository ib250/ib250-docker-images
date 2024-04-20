from nixos/nix:latest as build

workdir work
copy nix.conf nix.conf
env NIX_CONF_DIR=/work
copy default.nix .
copy flake.nix .
copy flake.lock .
# run nix flake check --no-build '.#'$ATTR

arg ATTR
run nix profile install -j8 '.#'$ATTR --impure
