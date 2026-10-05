#!/bin/bash

source /etc/profile
echo 1 > /proc/sys/net/ipv4/ip_forward
/helper-B.sh &
/helper-C.sh &
source /tmux-launch.sh

exec "$@"
