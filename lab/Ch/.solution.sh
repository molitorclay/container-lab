#!/usr/bin/env bash
TARGET=/home/jerry/lab/Ch/alpine

# Add Albert directly to Alpine's /etc (jerry owns alpine files, no chroot needed)
if ! grep -q '^Albert:' "$TARGET/etc/passwd"; then
    echo 'Albert:x:1001:1001::/home/Albert:/bin/sh' >> "$TARGET/etc/passwd"
    echo 'Albert::1::::::' >> "$TARGET/etc/shadow"
    echo 'Albert:x:1001:' >> "$TARGET/etc/group"
    mkdir -p "$TARGET/home/Albert"
fi

# Create the file bomb.sh will be bind-mounted onto
mkdir -p "$TARGET/lab"
touch "$TARGET/lab/bomb.sh"

# Alpine minirootfs ships no resolv.conf — bomb needs DNS for whois.ripe.net
echo "nameserver 8.8.8.8" > "$TARGET/etc/resolv.conf"

# Set up network namespace with Swiss-registered IP + reachable gateway.
# Guest needs both 10.2.0.2 (so 10.2.0.1 gateway is on-link) and 146.67.140.90
# (sbb.ch, so whois returns CH). The Swiss IP is primary so the bomb's
# `ip addr show | head -1` picks it up.
sudo ip netns add ch_ns
sudo ip link add veth_h type veth peer name veth_g
sudo ip link set veth_g netns ch_ns
sudo ip link set veth_h up
sudo ip addr add 10.2.0.1/24 dev veth_h

sudo ip netns exec ch_ns ip link set lo up
sudo ip netns exec ch_ns ip link set veth_g up
sudo ip netns exec ch_ns ip addr add 194.150.245.142/24 dev veth_g
sudo ip netns exec ch_ns ip addr add 10.2.0.2/24 dev veth_g
sudo ip netns exec ch_ns ip route add default via 10.2.0.1

sudo nft add table ip nat || true
sudo nft add chain ip nat postrouting '{ type nat hook postrouting priority 100; }' || true
sudo nft add rule ip nat postrouting ip saddr 10.2.0.0/24 masquerade

# Enter network namespace, create UTS/mount/PID namespaces, bind-mount bomb.sh
# into alpine (inside the mount ns so it doesn't leak to host), pivot_root in.
sudo ip netns exec ch_ns \
    unshare --mount --pid --uts --fork bash -c "
        hostname Bern
        mount --make-rprivate /
        mount --bind '$TARGET' '$TARGET'
        mount --bind '$(pwd)/bomb.sh' '$TARGET/lab/bomb.sh'
        mount -t proc  proc  '$TARGET/proc'
        mount -t sysfs sysfs '$TARGET/sys'
        mount --bind   /dev  '$TARGET/dev'
        mkdir -p '$TARGET/.old_root'
        pivot_root '$TARGET' '$TARGET/.old_root'
        /bin/umount -l /.old_root
        /bin/rmdir /.old_root
        exec /bin/su Albert -c 'export TZ=CET-1CEST,M3.5.0,M10.5.0/3; exec /bin/sh /lab/bomb.sh'
    "
