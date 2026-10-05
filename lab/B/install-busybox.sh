#!/usr/bin/env bash
mkdir -p bin etc
curl -fsSL https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox -o bin/busybox
chmod +x bin/busybox
bin/busybox --install bin/

echo 'export PATH=/bin' > etc/profile

# unshare --user --map-root-user chroot . /bin/busybox sh -l
