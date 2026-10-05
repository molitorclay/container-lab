#!/usr/bin/env bash
mkdir -p "$(dirname "$0")/alpine"
curl -fsSL https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-minirootfs-3.24.0-x86_64.tar.gz \
    | tar -xz -C "$(dirname "$0")/alpine"
