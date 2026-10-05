#!/usr/bin/env sh
# This bomb needs a network to survive!
# It needs its own network namespace with a working interface.
# If it shares the host's network it will explode.
# If it can't bind a privileged port it will explode.
# If it can't reach the internet it will explode.

TMUX_LABEL="C"

tmux_rename() {
    printf '\033k%s\033\\' "$1"
}

explode() {
    printf "💥 BOOM!!! 💥\n"
    tmux_rename "${TMUX_LABEL}💥"
    (sleep 5; tmux_rename "${TMUX_LABEL}🔴") &
    exit 1
}

# Check loopback is up
if ! ip link show lo 2>/dev/null | grep -qE 'state (UP|UNKNOWN)'; then
    printf "❌ Loopback is not up\n"
    explode
fi
printf "✅ Loopback is up\n"
sleep 0.2

# Check a non-loopback interface exists with an IP
IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -1)
if [ -z "$IFACE" ]; then
    printf "❌ No network interface found\n"
    explode
fi
MY_IP=$(ip -4 addr show dev "$IFACE" 2>/dev/null | grep -oE 'inet [0-9.]+' | awk '{print $2}')
if [ -z "$MY_IP" ]; then
    printf "❌ No IP assigned to %s\n" "$IFACE"
    explode
fi
printf "✅ Interface %s has IP %s\n" "$IFACE" "$MY_IP"
sleep 0.2

# Check we are NOT on the host's network (host uses 172.x docker bridge)
HOST_RANGE=$(echo "$MY_IP" | grep -cE '^172\.')
if [ "$HOST_RANGE" -gt 0 ]; then
    printf "❌ Using host network — set up a separate namespace\n"
    explode
fi
printf "✅ Not on host network\n"
sleep 0.2

# Check we can bind a privileged port
nc -l -p 80 &
NC_PID=$!
sleep 0.2
if ! kill -0 $NC_PID 2>/dev/null; then
    printf "❌ Cannot bind privileged port 80\n"
    explode
fi
kill $NC_PID 2>/dev/null
printf "✅ Can bind privileged port\n"
sleep 0.2

# Check internet access
if ! nc -zw2 8.8.8.8 53 2>/dev/null; then
    printf "❌ No internet access\n"
    explode
fi
printf "✅ Internet reachable\n"
sleep 0.2

printf "🎉 You defused the bomb!!!\n"
tmux_rename "$TMUX_LABEL🟢"
