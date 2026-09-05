#!/usr/bin/env python3
"""Rename exported xcresult attachments back to the names the test gave them.

`xcresulttool export attachments` writes "<name>_0_<uuid>.png" and records the
readable name in manifest.json. The gallery builder keys off week_NNN_portrait
/ week_NNN_landscape, so restore those.

    python3 scripts/name-attachments.py <dir>
"""
import json
import os
import re
import shutil
import sys

out = sys.argv[1]
manifest = os.path.join(out, "manifest.json")
if not os.path.exists(manifest):
    sys.exit("no manifest.json — attachments were not exported")

renamed = 0
for entry in json.load(open(manifest)):
    for a in entry.get("attachments", []):
        name = a.get("suggestedHumanReadableName")
        src = os.path.join(out, a["exportedFileName"])
        if not (name and os.path.exists(src)):
            continue
        # The readable name still carries xcresulttool's "_0_<uuid>" suffix.
        name = re.sub(r"_\d+_[0-9A-F-]{36}(?=\.png$|$)", "", name)
        if not name.endswith(".png"):
            name += ".png"
        shutil.move(src, os.path.join(out, name))
        renamed += 1

os.remove(manifest)
print(f"{renamed} captures in {out}")
