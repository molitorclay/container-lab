#!/usr/bin/env sh
# This bomb is about to blow up!
# It's very shy — if it sees another process it will explode.
# It's also homesick — if it's not on jerry-pc it will explode.

tmux_label() {
    tmux display-message -p '#W' 2>/dev/null | sed 's/[^[:alnum:]].*$//'
}

explode() {
    printf "💥 BOOM!!! 💥\n"
    if [ -n "$TMUX" ]; then
        LABEL=$(tmux_label)
        tmux rename-window "${LABEL}💥"
        (sleep 5; tmux rename-window "${LABEL}🔴") &
    fi
    exit 1
}

if [ "$(hostname)" != "jerry-pc" ]; then
    printf "❌ This is %s, I want jerry-pc!\n" "$(hostname)"
    explode
fi
printf "✅ Running on %s\n" "$(hostname)"
sleep 0.2

PIDCOUNT=$(ps -e --no-headers | wc -l)
if [ "$PIDCOUNT" -gt 5 ]; then
    printf "❌ Too many processes: %d\n" "$PIDCOUNT"
    explode
fi
printf "✅ Number of processes: %d\n" "$PIDCOUNT"
sleep 0.2

printf "🎉 You defused the bomb!!!\n"
if [ -n "$TMUX" ]; then
    tmux rename-window "$(tmux_label)🟢"
fi
