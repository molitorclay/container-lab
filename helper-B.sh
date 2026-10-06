#!/bin/bash
FLAG_DIR=/home/jerry/lab

while true; do
    T=$(date +%s)
    for name in flag_public flag_private; do
        f="$FLAG_DIR/$name"
        if [ ! -e "$f" ]; then
            touch "$f"
            chmod 644 "$f"
        fi
        printf '%s' "$(printf '%s%s' "$T" "$name" | sha256sum | cut -d' ' -f1)" > "$f"
    done
    sleep 1
done
