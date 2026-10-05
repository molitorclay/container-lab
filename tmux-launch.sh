#!/bin/bash

# Color indices: rose, steel blue, sea green, medium purple, peach, cadet blue, sage
PASTEL_COLORS=(211 110 114 141 215 116 108)

LABS_DIR=/home/jerry/lab
FIRST=1
INDEX=0

for lab in "$LABS_DIR"/*/; do
    name=$(basename "$lab")
    wname="${name}🔴"
    color=${PASTEL_COLORS[$((INDEX % ${#PASTEL_COLORS[@]}))]}

    if [ $FIRST -eq 1 ]; then
        tmux new-session -d -s lab -n "$wname" -c "$lab"
        FIRST=0
    else
        tmux new-window -t lab -n "$wname" -c "$lab"
    fi

    tmux split-window -v -t "lab:$wname" -c "$lab"
    tmux set-window-option -t "lab:$wname" @color "color$color"
    tmux set-window-option -t "lab:$wname" window-status-style "bg=color$color,fg=color232"
    tmux set-window-option -t "lab:$wname" window-status-current-style "bg=color$color,fg=color232,bold"
    tmux select-pane -t "lab:$wname.1"

    INDEX=$((INDEX + 1))
done

# Update border color to match the active window on every window switch
tmux set-hook -g after-select-window \
    'set-option -g pane-active-border-style "fg=#{@color}"; set-option -g pane-border-style "fg=#{@color}"'

tmux select-window -t lab:1
tmux attach-session -t lab
