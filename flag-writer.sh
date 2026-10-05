#!/bin/bash
FLAG_DIR=/home/jerry/lab

while true; do
    T=$(date +%s)
    printf '%s' "$(printf '%s%s' "$T" "flag_public"  | sha256sum | cut -d' ' -f1)" > "$FLAG_DIR/flag_public"
    printf '%s' "$(printf '%s%s' "$T" "flag_private" | sha256sum | cut -d' ' -f1)" > "$FLAG_DIR/flag_private"
    sleep 1
done
