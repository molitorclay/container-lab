#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

./whiteout-touch 4/edits.md

mkdir -p mount-here
sudo mount -t overlay overlay -o lowerdir=4:3:2:1 mount-here

./bomb.sh
