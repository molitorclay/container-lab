#!/usr/bin/env bash
# Local test: build the lab image, then for each lab run bomb.sh standalone
# (expect explode) and .solution.sh (expect defuse).
set -euo pipefail

cd "$(dirname "$0")"

IMAGE=${IMAGE:-container-lab-test}

if command -v docker >/dev/null; then
    RUNTIME=docker
elif command -v podman >/dev/null; then
    RUNTIME=podman
else
    echo "need docker or podman" >&2; exit 1
fi

echo "=== building $IMAGE ==="
"$RUNTIME" build -t "$IMAGE" . >/dev/null

echo "=== running tests ==="
exec "$RUNTIME" run --privileged --rm --entrypoint bash "$IMAGE" -c '
set -u
/helper-B.sh &
/helper-C.sh &
sleep 1

FAIL=0

run_as() {
    local user=$1 lab=$2 cmd=$3
    if [ "$user" = root ]; then
        bash -c "cd /home/jerry/lab/$lab && $cmd"
    else
        su - "$user" -c "cd ~/lab/$lab && $cmd"
    fi
}

check_bomb_fails() {
    local user=$1 lab=$2
    if run_as "$user" "$lab" "./bomb.sh" >/dev/null 2>&1; then
        echo "FAIL lab $lab: bomb defused without solution"
        FAIL=1
    else
        echo "ok   lab $lab: bomb exploded standalone"
    fi
}

check_solution_passes() {
    local user=$1 lab=$2
    local out
    if out=$(run_as "$user" "$lab" "./.solution.sh" 2>&1); then
        if echo "$out" | grep -qE "defused|home"; then
            echo "ok   lab $lab: solution defused"
        else
            echo "FAIL lab $lab: solution exit 0 but no defuse message"
            echo "$out"
            FAIL=1
        fi
    else
        echo "FAIL lab $lab: solution exited non-zero"
        echo "$out"
        FAIL=1
    fi
}

for pair in "jerry A" "jerry B" "jerry C" "jerry Ch" "root D"; do
    read -r user lab <<< "$pair"
    check_bomb_fails "$user" "$lab"
    check_solution_passes "$user" "$lab"
done

exit $FAIL
'
