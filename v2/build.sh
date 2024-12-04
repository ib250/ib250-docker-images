#!/usr/bin/env bash

set -eou pipefail

nix upgrade-nix || true

echo 'extra-experimental-features = nix-command flakes' >> /etc/nix/nix.conf
echo 'filter-syscalls = false' >> /etc/nix/nix.conf

build_args=""
for attr in "$@"; do
    nix build -j8 '.#'${attr}
    if ! cp $(realpath result) ${out_link_path}/.
    then
        echo "Warning: attempted to copy $(realpath result) to ${out_link_path} failed"
    fi
done

rm -rf result
