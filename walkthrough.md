# Walkthrough

## chroot

```sh
chroot /path/to/rootfs /bin/sh
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
TARGET=/path/to/rootfs
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

### uts

```sh
sudo unshare --uts bash
hostname new-hostname
```

### pid

```sh
sudo unshare --pid --fork bash -c "
  mount -t proc proc /proc
  exec bash
"
```

### pid + uts + mount

```sh
sudo unshare --mount --pid --fork --uts bash -c "
  hostname new-hostname
  mount -t proc proc /proc
  exec bash
"
```

### net

Create namespace and veth pair:
```sh
sudo ip netns add my_namespace

sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth1 netns my_namespace

sudo ip link set veth0 up
sudo ip addr add 10.0.0.1/24 dev veth0
```

Enter and configure (nsenter):
```sh
sudo nsenter --net=/var/run/netns/my_namespace bash
ip link set veth1 up
ip addr add 10.0.0.2/24 dev veth1
ip link set lo up
```

OR via ip netns exec:
```sh
# sudo ip netns exec my_namespace ip link set veth1 up
# sudo ip netns exec my_namespace ip addr add 10.0.0.2/24 dev veth1
# sudo ip netns exec my_namespace ip link set lo up
```

NAT (outbound internet access from namespace):
```sh
sudo nft add table ip nat
sudo nft add chain ip nat postrouting '{ type nat hook postrouting priority 100; }'
sudo nft add rule ip nat postrouting ip saddr 10.0.0.0/24 masquerade
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo ip netns exec my_namespace ip route add default via 10.0.0.1
```

## OCI images

Build and save an image's layers to a local directory (OCI layout):
```sh
podman build -t my-image .
podman save --format oci-dir -o ./oci-layers my-image
```

Layer tarballs land in `./oci-layers/blobs/sha256/`. Walk `index.json` → manifest → config to see the ordered layer list.

Podman `--format` values: `oci-dir`, `oci-archive`, `docker-dir`, `docker-archive` (default).

Docker:
```sh
docker build -t my-image .
docker save my-image -o my-image.tar
mkdir layers && tar -xf my-image.tar -C layers
```
Each layer lives at `layers/<sha256>/layer.tar`.
