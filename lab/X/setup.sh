#!/usr/bin/env bash
# Build the lab image, save its layers, and extract them into numbered dirs
# ready to mount with overlayfs.
set -euo pipefail

IMAGE=mylab
OCI_DIR=./oci
LAYERS=./layers

# Jerry's home has symlinks (config/, helper-*.sh, entrypoint.sh) pointing
# outside the build context. Dereference them into a temp build dir so
# podman can COPY their contents.
BUILD_CTX=$(mktemp -d)
trap 'rm -rf "$BUILD_CTX"' EXIT

cp -a  ~/lab          "$BUILD_CTX/lab"              # keep internal symlinks (alpine's /bin → busybox etc.)
mkdir -p "$BUILD_CTX/config"
cp -L  ~/config/tmux.conf    "$BUILD_CTX/config/tmux.conf"
cp -L  ~/config/ps1.sh       "$BUILD_CTX/config/ps1.sh"
cp -L  ~/tmux-launch.sh ~/helper-B.sh ~/helper-C.sh ~/entrypoint.sh ~/Dockerfile "$BUILD_CTX/"
cp     /depth         "$BUILD_CTX/depth"

podman build -t "$IMAGE" "$BUILD_CTX"

rm -rf "$OCI_DIR" "$LAYERS"
podman save --format oci-dir -o "$OCI_DIR" "$IMAGE"

./extract-layers.py "$OCI_DIR" "$LAYERS"

echo
echo "Layers extracted to $LAYERS/{1..N}"
echo "Mount them with:"
echo
echo "  LOWER=\$(ls -1v $LAYERS | tac | sed 's|^|$PWD/$LAYERS/|' | paste -sd:)"
echo "  sudo mount -t overlay overlay -o lowerdir=\$LOWER /mnt/merged"
