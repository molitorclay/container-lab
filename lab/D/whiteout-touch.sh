#!/usr/bin/env bash
# Shadow a file by creating an empty version at the given path.
# Not a real whiteout — the file is still visible in the merged view,
# just empty. Usage: whiteout-touch.sh <path>  (e.g. whiteout-touch.sh 4/edits.md)
touch "$1"
