# Walkthrough

## chroot

```sh
chroot the/new/root /bin/sh
```

Unprivileged (busybox):
```sh
unshare --user --map-root-user chroot . /bin/busybox sh -c 'export PATH=/bin; exec sh'
```

Into Alpine:
```sh
TARGET=/path/to/alpine
sudo unshare --mount --pid --fork bash -c "
  mount -t proc  proc   $TARGET/proc
  mount -t sysfs sysfs  $TARGET/sys
  mount --bind   /dev   $TARGET/dev
  chroot $TARGET /bin/ash -l
"
```

## pivot_root

Minimal:
```sh
TARGET=the/new/root
unshare --mount bash
mount --bind $TARGET $TARGET
mkdir -p $TARGET/.old_root
pivot_root $TARGET $TARGET/.old_root
exec /bin/sh
```

Into Alpine:
```sh
TARGET=/path/to/alpine
sudo unshare --mount --pid --fork bash -c "
  mount --make-rprivate /
  mount --bind $TARGET $TARGET
  mount -t proc  proc   $TARGET/proc
  mount -t sysfs sysfs  $TARGET/sys
  mount --bind   /dev   $TARGET/dev
  mkdir -p $TARGET/.old_root
  pivot_root $TARGET $TARGET/.old_root
  exec /bin/ash -c '/bin/umount -l /.old_root; /bin/rmdir /.old_root; exec /bin/ash -l'
"
```

## Namespaces

### proc

### net

Create namespace and veth pair:
```sh
sudo ip netns add bunker

sudo ip link add veth_host type veth peer name veth_guest
sudo ip link set veth_guest netns bunker

sudo ip link set veth_host up
sudo ip addr add 10.0.0.1/24 dev veth_host
```

Enter and configure (nsenter):
```sh
sudo nsenter --net=/var/run/netns/bunker bash
ip link set veth_guest up
ip addr add 10.0.0.2/24 dev veth_guest
ip link set lo up
```

OR via ip netns exec:
```sh
# sudo ip netns exec bunker ip link set veth_guest up
# sudo ip netns exec bunker ip addr add 10.0.0.2/24 dev veth_guest
# sudo ip netns exec bunker ip link set lo up
```

NAT (outbound internet access from namespace):
```sh
sudo nft add table ip nat
sudo nft add chain ip nat postrouting '{ type nat hook postrouting priority 100; }'
sudo nft add rule ip nat postrouting ip saddr 10.0.0.0/24 masquerade
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo ip netns exec bunker ip route add default via 10.0.0.1
```
