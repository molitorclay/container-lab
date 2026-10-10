#!/usr/bin/env bash
unshare --user --map-root-user --mount --pid --fork --uts bash -c "hostname jerry-pc && mount -t proc proc /proc && exec bash bomb.sh"

# sudo unshare --mount --pid --fork --uts bash -c "hostname jerry-pc && mount -t proc proc /proc && exec bash bomb.sh"
