#!/bin/bash
source /etc/profile
echo 1 > /proc/sys/net/ipv4/ip_forward
base64 -d /Dockerfile.base64 > ~jerry/Dockerfile
chown jerry:jerry ~jerry/Dockerfile
/helper-B.sh &
/helper-C.sh &
source /tmux-launch.sh
exec "$@"
