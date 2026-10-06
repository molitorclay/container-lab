#!/usr/bin/env python3
"""Extract OCI image layers into numbered directories for overlayfs mounting.

Usage: extract-layers.py <oci-dir> <out-dir>
"""
import json
import os
import sys
import tarfile
from pathlib import Path


def main(oci_dir: Path, out_dir: Path) -> None:
    index = json.loads((oci_dir / "index.json").read_text())
    manifest_digest = index["manifests"][0]["digest"].split(":", 1)[1]
    manifest = json.loads((oci_dir / "blobs" / "sha256" / manifest_digest).read_text())

    out_dir.mkdir(parents=True, exist_ok=True)

    for i, layer in enumerate(manifest["layers"], start=1):
        digest = layer["digest"].split(":", 1)[1]
        blob = oci_dir / "blobs" / "sha256" / digest
        dest = out_dir / str(i)
        dest.mkdir(exist_ok=True)
        print(f"[{i:>3}] {digest[:12]}  {layer['size']:>12,} B  -> {dest}")
        with tarfile.open(blob, "r:*") as tar:
            tar.extractall(dest, filter="tar")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        sys.exit(1)
    main(Path(sys.argv[1]), Path(sys.argv[2]))
