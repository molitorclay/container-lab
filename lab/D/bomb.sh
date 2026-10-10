#!/usr/bin/env sh
# This bomb needs its manuscript fixed and the editor's notes gone.
# Overlay layers 1-4 onto mount-here so only the fixed manuscript shows.

TMUX_LABEL="D"

tmux_rename() {
    printf '\033k%s\033\\' "$1"
}

explode() {
    printf "💥 BOOM!!! 💥\n"
    tmux_rename "${TMUX_LABEL}💥"
    (sleep 5; tmux_rename "${TMUX_LABEL}🔴") &
    exit 1
}

cd "$(dirname "$0")"

if [ ! -d mount-here ]; then
    printf "❌ mount-here does not exist\n"
    explode
fi
printf "✅ mount-here exists\n"
sleep 0.2

if [ ! -f mount-here/manuscript.md ]; then
    printf "❌ manuscript.md not visible in mount-here\n"
    explode
fi
printf "✅ manuscript.md is visible\n"
sleep 0.2

if ! grep -q 'The quick brown fox jumps over the lazy dog\.' mount-here/manuscript.md; then
    printf "❌ manuscript.md is not fixed\n"
    explode
fi
printf "✅ manuscript.md is fixed\n"
sleep 0.2

if [ -e mount-here/edits.md ]; then
    printf "❌ edits.md is still visible\n"
    explode
fi
printf "✅ edits.md is hidden\n"
sleep 0.2

printf "🎉 You defused the bomb!!!\n"
tmux_rename "${TMUX_LABEL}🟢"
