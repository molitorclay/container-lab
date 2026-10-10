#!/usr/bin/env bash
# Build the lab image, save its layers, and extract them into numbered dirs
# ready to mount with overlayfs.
set -euo pipefail

IMAGE=mylab
OCI_DIR=./oci
LAYERS=./layers

cp /depth ~/depth
podman build -t "$IMAGE" ~/

rm -rf "$OCI_DIR" "$LAYERS"
podman save --format oci-dir -o "$OCI_DIR" "$IMAGE"

./extract-layers.py "$OCI_DIR" "$LAYERS"

echo
echo "Layers extracted to $LAYERS/{1..N}"
echo "Mount them with:"
echo
echo "  LOWER=\$(ls -1v $LAYERS | tac | sed 's|^|$PWD/$LAYERS/|' | paste -sd:)"
echo "  sudo mount -t overlay overlay -o lowerdir=\$LOWER /mnt/merged"
