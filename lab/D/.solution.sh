#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "This solution requires root — run: su root"
    exit 1
fi

cd "$(dirname "$0")"

mkdir -p mount-here

# Layer 4 lives on the container's overlayfs, which can't be an overlay upperdir.
# Mount a tmpfs over it to give overlayfs a real filesystem.
mount -t tmpfs tmpfs 4
mkdir 4/upper 4/work

# Writable overlay — deleting through merged makes overlayfs create a whiteout
# in upperdir using its own code path (bypasses the mknod syscall restriction).
mount -t overlay overlay \
    -o lowerdir=3:2:1,upperdir=4/upper,workdir=4/work \
    mount-here

rm mount-here/edits.md
umount mount-here

# Move the whiteout up to 4/, clean up scratch dirs
mv 4/upper/edits.md 4/
rm -rf 4/upper 4/work

# Final read-only stack
mount -t overlay overlay -o lowerdir=4:3:2:1 mount-here
