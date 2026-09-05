#!/usr/bin/env python3
"""Fail the capture run if any shot's pixels disagree with its name.

A landscape screenshot whose raster is still portrait is the one capture bug
that survives every visual check: Preview honors the EXIF orientation tag and
shows it upright, so it looks correct locally and publishes sideways. Catch it
here, before the compositor ever sees it.

    python3 scripts/check-orientation.py <dir>
"""
import os
import sys

from PIL import Image

out = sys.argv[1]
bad = []
for name in sorted(os.listdir(out)):
    if not name.endswith(".png"):
        continue
    width, height = Image.open(os.path.join(out, name)).size
    wants_landscape = "_landscape" in name
    print(f"  {name}  {width}x{height}")
    if (width > height) != wants_landscape:
        shape = "landscape" if wants_landscape else "portrait"
        bad.append(f"{name}: {width}x{height} but named {shape}")

if bad:
    sys.exit("ORIENTATION MISMATCH:\n  " + "\n  ".join(bad))
