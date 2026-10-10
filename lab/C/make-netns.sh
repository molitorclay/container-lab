#!/usr/bin/env bash
set -euo pipefail

NS=my-netns
HOST_IF="${NS}_h"
GUEST_IF="${NS}_g"
HOST_IP=10.0.0.1
GUEST_IP=10.0.0.2
SUBNET=10.0.0.0/24

sudo ip netns add "$NS"
sudo ip link add "$HOST_IF" type veth peer name "$GUEST_IF"
sudo ip link set "$GUEST_IF" netns "$NS"

# Host side up
sudo ip link set "$HOST_IF" up
sudo ip addr add "$HOST_IP/24" dev "$HOST_IF"

# Guest side up (inside namespace)
sudo ip netns exec "$NS" ip link set lo up
sudo ip netns exec "$NS" ip link set "$GUEST_IF" up
sudo ip netns exec "$NS" ip addr add "$GUEST_IP/24" dev "$GUEST_IF"
sudo ip netns exec "$NS" ip route add default via "$HOST_IP"

# NAT (idempotent)
sudo nft add table ip nat || true
sudo nft add chain ip nat postrouting '{ type nat hook postrouting priority 100; }' || true
sudo nft add rule ip nat postrouting ip saddr "$SUBNET" masquerade

echo "host-if:  $HOST_IF"
echo "guest-if: $GUEST_IF"
echo "netns:    $NS"
