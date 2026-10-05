#!/bin/bash

source /etc/profile
/flag-writer.sh &
source /tmux-launch.sh

exec "$@"
