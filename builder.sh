#!/usr/bin/env bash

set -eou pipefail

for attr in "$@"
do
    nix build '.#'${attr} -j8 --out-link /${attr} --print-out-paths
done
