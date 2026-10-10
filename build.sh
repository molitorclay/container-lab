#!/usr/bin/env bash
set -euo pipefail

if command -v podman >/dev/null 2>&1; then
    RUNTIME=podman
elif command -v docker >/dev/null 2>&1; then
    RUNTIME=docker
else
    printf '❌ neither podman nor docker is installed\n' >&2
    exit 1
fi

printf 'using %s\n' "$RUNTIME"
"$RUNTIME" build -t container-lab .
"$RUNTIME" run -it --privileged container-lab
