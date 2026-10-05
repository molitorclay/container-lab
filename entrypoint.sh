#!/bin/bash

source /etc/profile
/helper-B.sh &
/helper-C.sh &
source /tmux-launch.sh

exec "$@"
