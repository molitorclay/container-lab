#!/usr/bin/env bash
cd ~/lab/B

./install-busybox.sh

touch flag_public
unshare --user --map-root-user --mount bash -c "
    mount --bind -o ro ~/lab/flag_public flag_public
    unshare --user --map-root-user chroot . /bin/busybox sh -l bomb.sh
"
