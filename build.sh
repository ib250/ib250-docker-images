#!/usr/bin/env bash

set -eou pipefail

DRYRUN_CMD=
if [[ "${DRYRUN:-0}" -eq "1" ]]
then
    DRYRUN_CMD=echo
fi

echo 'extra-experimental-features = nix-command flakes' >> /etc/nix/nix.conf
echo 'filter-syscalls = false' >> /etc/nix/nix.conf

echo "targets=$TARGETS"

IFS=':' read -a targets_ <<< $TARGETS

build_args=""
for attr in ${targets_[*]}; do
    if [[ ${DRYRUN:-0} -eq "1" ]]
    then
        nix path-info --recursive '.#'${attr}
    else
        nix build -j8 '.#'${attr}
    fi

    if ! $DRYRUN_CMD cp $(realpath result) ${out_link_path}/.
    then
        echo "Warning: attempted to copy $(realpath result) to ${out_link_path} failed"
    fi
done

$DRYRUN_CMD rm -rf result
