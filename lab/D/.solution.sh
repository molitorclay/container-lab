#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Whiteout: a char(0,0) device at the same path hides the file in a lower layer
sudo mknod 4/edits.md c 0 0

mkdir -p mount-here

sudo mount -t overlay overlay -o lowerdir=4:3:2:1 mount-here
