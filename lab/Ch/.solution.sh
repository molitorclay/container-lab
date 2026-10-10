#!/usr/bin/env bash
TARGET=/home/jerry/lab/Ch/alpine

# Add Albert to Alpine (idempotent)
if ! grep -q '^Albert:' "$TARGET/etc/passwd"; then
    chroot "$TARGET" adduser -D Albert
fi

# Bind-mount bomb.sh into Alpine so it's accessible after pivot_root
mkdir -p "$TARGET/lab"
sudo mount --bind "$(pwd)/bomb.sh" "$TARGET/lab/bomb.sh"

# Set up network namespace with a Swiss-registered IP (SWITCH Education, 195.176.0.0/14)
sudo ip netns add ch_ns
sudo ip link add veth_h type veth peer name veth_g
sudo ip link set veth_g netns ch_ns
sudo ip link set veth_h up
sudo ip addr add 10.2.0.1/24 dev veth_h

sudo ip netns exec ch_ns ip link set lo up
sudo ip netns exec ch_ns ip link set veth_g up
sudo ip netns exec ch_ns ip addr add 195.176.1.1/24 dev veth_g
sudo ip netns exec ch_ns ip route add default via 10.2.0.1

sudo nft add table ip nat || true
sudo nft add chain ip nat postrouting '{ type nat hook postrouting priority 100; }' || true
sudo nft add rule ip nat postrouting ip saddr 10.2.0.0/24 masquerade

# Enter network namespace, then create UTS/mount/PID namespaces and pivot_root into Alpine
sudo ip netns exec ch_ns \
    unshare --mount --pid --uts --fork bash -c "
        hostname Bern
        mount --make-rprivate /
        mount --bind '$TARGET' '$TARGET'
        mount -t proc  proc  '$TARGET/proc'
        mount -t sysfs sysfs '$TARGET/sys'
        mount --bind   /dev  '$TARGET/dev'
        mkdir -p '$TARGET/.old_root'
        pivot_root '$TARGET' '$TARGET/.old_root'
        /bin/umount -l /.old_root
        /bin/rmdir /.old_root
        exec /bin/su Albert -c 'export TZ=CET; exec /bin/sh /lab/bomb.sh'
    "
