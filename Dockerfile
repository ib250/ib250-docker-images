from nixos/nix:latest as build

run mkdir work
workdir work
copy nix.conf nix.conf
env NIX_CONF_DIR=/work

arg ATTR
copy default.nix .
run nix copy --to /tmp/out -f default.nix $ATTR --no-require-sigs
run nix-collect-garbage -d

from scratch
copy --from=build /tmp/out/nix/store /nix/store
