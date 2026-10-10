#!/usr/bin/env bash
set -euo pipefail

if command -v docker >/dev/null 2>&1; then
    RUNTIME=docker
elif command -v podman >/dev/null 2>&1; then
    RUNTIME=podman
else
    printf '❌ neither docker nor podman is installed\n' >&2
    exit 1
fi

printf 'using %s\n' "$RUNTIME"
"$RUNTIME" build -t container-lab .
"$RUNTIME" run -it --privileged container-lab
