from --platform=$BUILDPLATFORM nixos/nix:latest as build
arg ATTR
run mkdir work
workdir work
copy default.nix .
env NIX_CONFIG="extra-experimental-features = nix-command flakes"
run nix build -f default.nix $ATTR
run nix copy --to /tmp/out -f default.nix $ATTR --no-require-sigs
run nix-collect-garbage -d

from scratch
copy --from=build /tmp/out/nix/store /nix/store
