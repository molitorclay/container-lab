#!/bin/bash
CAP_BND=$(awk '/^CapBnd:/ {print $2}' /proc/self/status)
if (( 0x$CAP_BND & 0x200000 )) ; then
    : # CAP_SYS_ADMIN in bounding set — privileged
else
    printf '❌ container must be run with --privileged\n' >&2
    exit 1
fi

source /etc/profile
base64 -d /Dockerfile.base64 > ~jerry/Dockerfile
chown jerry:jerry ~jerry/Dockerfile
/helper-B.sh &
/helper-C.sh &
source /tmux-launch.sh
exec "$@"
