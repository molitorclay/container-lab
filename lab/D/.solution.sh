#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Mark edits.md as a whiteout via user.overlay.whiteout xattr. Combined with
# the overlay's userxattr option below, this is interpreted as a deletion.
touch 4/edits.md
setfattr -n user.overlay.whiteout -v y 4/edits.md

mkdir -p mount-here

# Mount the overlay inside a user namespace so jerry gets CAP_SYS_ADMIN
# scoped to that namespace, which permits an unprivileged overlay mount.
# userxattr makes overlay honor user.overlay.* instead of trusted.overlay.*,
# so the whiteout above takes effect without root.
unshare -r --mount bash -c '
    mount -t overlay overlay -o lowerdir=4:3:2:1,userxattr mount-here
    ./bomb.sh
'
