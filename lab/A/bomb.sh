#!/usr/bin/env sh
# This bomb is about to blow up!
# It's very shy — if it sees another process it will explode.
# It's also homesick — if it's not on jerry-pc it will explode.

TMUX_LABEL="A"

tmux_rename() {
    printf '\033k%s\033\\' "$1"
}

explode() {
    printf "💥 BOOM!!! 💥\n"
    tmux_rename "${TMUX_LABEL}💥"
    (sleep 5; tmux_rename "${TMUX_LABEL}🔴") &
    exit 1
}

if [ "$(hostname)" != "jerry-pc" ]; then
    printf "❌ This is %s, I want jerry-pc!\n" "$(hostname)"
    explode
fi
printf "✅ Running on %s\n" "$(hostname)"
sleep 0.2

PIDCOUNT=$(ps a --no-headers | wc -l)
if [ "$PIDCOUNT" -lt 1 ] || [ "$PIDCOUNT" -gt 5 ]; then
    printf "❌ Process count out of range: %d\n" "$PIDCOUNT"
    explode
fi
printf "✅ Number of processes: %d\n" "$PIDCOUNT"
sleep 0.2

printf "🎉 You defused the bomb!!!\n"
tmux_rename "$TMUX_LABEL🟢"
