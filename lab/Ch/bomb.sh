#!/usr/bin/env sh
# This bomb is named Albert, and he is homesick for Switzerland.
# Put him by some mountains, set his system time to CET, and give him a Swiss IP.

TMUX_LABEL="Ch"

tmux_rename() {
    printf '\033k%s\033\\' "$1"
}

explode() {
    printf "💥 BOOM!!! 💥\n"
    tmux_rename "${TMUX_LABEL}💥"
    (sleep 5; tmux_rename "${TMUX_LABEL}🔴") &
    exit 1
}

if [ "$(whoami)" != "Albert" ]; then
    printf "❌ I am %s, I want to be Albert!\n" "$(whoami)"
    explode
fi
printf "✅ Running as %s\n" "$(whoami)"
sleep 0.2

if [ "$(hostname)" != "Bern" ]; then
    printf "❌ I am in %s, I want to be in Bern!\n" "$(hostname)"
    explode
fi
printf "✅ Hostname is %s\n" "$(hostname)"
sleep 0.2

OS_ID=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
if [ "$OS_ID" != "alpine" ]; then
    printf "❌ OS is %s, I want Alpine!\n" "$OS_ID"
    explode
fi
printf "✅ Running on Alpine\n"
sleep 0.2

TZ_NAME=$(date +%Z)
if [ "$TZ_NAME" != "CET" ] && [ "$TZ_NAME" != "CEST" ]; then
    printf "❌ Timezone is %s, I want CET!\n" "$TZ_NAME"
    explode
fi
printf "✅ Timezone is %s\n" "$TZ_NAME"
sleep 0.2

IP=$(ip -4 addr show | grep -oE 'inet [0-9.]+' | awk '{print $2}' | grep -v '^127\.' | head -1)
COUNTRY=$(printf '%s\r\n' "$IP" | nc -w3 whois.ripe.net 43 2>/dev/null | grep -i '^country:' | head -1 | awk '{print $2}')
if [ "$COUNTRY" != "CH" ]; then
    printf "❌ IP country is %s, I want CH!\n" "$COUNTRY"
    explode
fi
printf "✅ IP is Swiss (%s)\n" "$COUNTRY"
sleep 0.2

printf "🎉 Albert is home!!!\n"
tmux_rename "${TMUX_LABEL}🟢"
