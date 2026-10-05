#!/usr/bin/env sh
# This bomb is going to blow up your files!
# Keep your files safe from the bomb, but be careful.
# If the bomb can't read flag_public it will blow up.
# If the bomb can write flag_public it will blow up.
# If the bomb can read flag_private it will blow up.

TMUX_LABEL="B"

tmux_rename() {
    printf '\033k%s\033\\' "$1"
}

explode() {
    printf "💥 BOOM!!! 💥\n"
    LABEL=$TMUX_LABEL
    tmux_rename "${LABEL}💥"
    (sleep 5; tmux_rename "${LABEL}🔴") &
    exit 1
}

if [ ! -r /flag_public ]; then
    printf "❌ Can't read /flag_public\n"
    explode
fi
ACTUAL=$(cat /flag_public)
FRESH=0
for OFFSET in 0 1 2; do
    EXPECTED=$(printf '%s%s' "$(($(date +%s) - OFFSET))" "flag_public" | sha256sum | cut -d' ' -f1)
    if [ "$ACTUAL" = "$EXPECTED" ]; then
        FRESH=1
        break
    fi
done
if [ "$FRESH" -eq 0 ]; then
    printf "❌ /flag_public is stale — mount it, don't copy it\n"
    explode
fi
printf "✅ Can read /flag_public\n"
sleep 0.2

if ( : >> /flag_public ) 2>/dev/null; then
    printf "❌ /flag_public is writable\n"
    explode
fi
printf "✅ /flag_public is read-only\n"
sleep 0.2

if [ -n "$(find / -xdev -name flag_private 2>/dev/null)" ]; then
    printf "❌ flag_private is readable\n"
    explode
fi
printf "✅ flag_private is hidden\n"
sleep 0.2

printf "🎉 You defused the bomb!!!\n"
tmux_rename "$TMUX_LABEL🟢"
