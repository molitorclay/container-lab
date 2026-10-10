#!/usr/bin/env bash
sudo ip netns add bunker

sudo ip link add veth_host type veth peer name veth_guest
sudo ip link set veth_guest netns bunker

sudo ip link set veth_host up
sudo ip addr add 10.0.0.1/24 dev veth_host

sudo ip netns exec bunker ip link set veth_guest up
sudo ip netns exec bunker ip addr add 10.0.0.2/24 dev veth_guest
sudo ip netns exec bunker ip link set lo up
sudo ip netns exec bunker ip route add default via 10.0.0.1

sudo nft add table ip nat
sudo nft add chain ip nat postrouting '{ type nat hook postrouting priority 100; }'
sudo nft add rule ip nat postrouting ip saddr 10.0.0.0/24 masquerade

sudo ip netns exec bunker bash bomb.sh
