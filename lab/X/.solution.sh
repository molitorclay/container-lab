#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "This solution requires root — run: su root"
    exit 1
fi

cd "$(dirname "$0")"

# Build + extract layers if not done yet
[ -d layers ] || su -c "./setup.sh" jerry

# This host caps our overlay stack at 9 lowerdirs (nested-overlay limit).
# Use the bottom 9 layers — the podman/stable base, which gives a
# working-ish rootfs. The lab's own Dockerfile layers aren't included
# but students still see overlay mounting + chroot work end to end.
mkdir -p mount-here
LOWER=$(ls -1v layers | head -n 9 | tac | sed "s|^|$PWD/layers/|" | paste -sd:)
mount -t overlay overlay -o lowerdir=$LOWER mount-here

# New mount/pid/uts namespaces, then chroot into the merged rootfs and
# mount /proc inside so ps/top work. Exits restore the host.
unshare --mount --pid --uts --fork \
    chroot mount-here /bin/bash -c 'mount -t proc proc /proc; exec /bin/bash'
