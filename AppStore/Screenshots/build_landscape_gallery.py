#!/usr/bin/env python3
"""Build the iPhone-landscape Screenker gallery from the trimmed captures.

The cartoons are all 1.39:1 and the 6.9" landscape canvas is 2.17:1, so a
full-bleed slide is impossible — roughly a third of the width is always spare.
Rather than leave it as letterbox, the art is matted like a framed print (the
app sells framed prints) on the brand cream, with the caption above it.

    python3 AppStore/Screenshots/build_landscape_gallery.py
"""
import json
import os
import shutil
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "raw-2026-09", "iphone-landscape-art")
OUT = os.path.join(HERE, "100burfords-landscape-2026-09.screenker")


def rgb(r, g, b, a=1.0):
    return {"red": r, "green": g, "blue": b, "opacity": a}


CREAM = rgb(0.984, 0.953, 0.890)
CREAM_DEEP = rgb(0.937, 0.863, 0.733)
INK = rgb(0.13, 0.13, 0.14)
SLATE = rgb(0.431, 0.325, 0.204)

STYLE = {
    "background": {"linearGradient": {"_0": {
        "startColor": CREAM, "endColor": CREAM_DEEP, "angleDegrees": 160}}},
    "captionAlignment": "center",
    "captionColor": INK,
    "captionFontFamily": {"system": {}},
    "captionFontSizeFraction": 0.062,
    "captionWeight": "regular",
    "secondaryCaptionColor": SLATE,
}

PRESET = {
    "id": "iphone-6.9-landscape",
    "displayName": "iPhone 6.9″ Landscape — 2868 × 1320",
    "pixelWidth": 2868,
    "pixelHeight": 1320,
}

# A white mat with a soft drop shadow — the cartoon reads as a framed print
# rather than as a screenshot floating on a background.
MAT = {
    "fill": rgb(1, 1, 1),
    "cornerRadiusFraction": 0.006,
    "paddingFraction": 0.012,
    "shadow": {"isEnabled": True, "radius": 44, "opacity": 0.30},
}

SLIDES = [
    ("week_115_landscape.png", "112 readers wrote in about this one",
     "The Upper West Side Places No Longer With Us"),
    ("week_001_landscape.png", "Start at week one, read all 117",
     "Walking Around Manhattan: The Times They Aren't Changin'"),
    ("week_033_landscape.png", "Turn the phone. The cartoon fills the screen.",
     "To Each Their Own — week 33"),
    ("week_083_landscape.png", "Every week since 2024, in order",
     "More Changes to the Upper West Side"),
    ("week_002_landscape.png", "Tap once for full screen, tap again to read on",
     "Whatever You Do and With Whom"),
    ("week_023_landscape.png", "2,787 reader comments, all in the app",
     "Take Care of Each Other"),
    ("week_044_landscape.png", "Print any cartoon, or order it framed",
     "There Goes the Upper West Side — Again"),
]


def main():
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(os.path.join(OUT, "originals"))

    items = []
    for filename, head, sub in SLIDES:
        ref = str(uuid.uuid4()).upper() + ".png"
        shutil.copyfile(os.path.join(ART, filename),
                        os.path.join(OUT, "originals", ref))
        items.append({"panel": {"_0": {
            "caption": {"text": head, "secondaryText": sub, "position": "top"},
            "framing": {"bare": {"cornerRadius": 0}},
            "id": str(uuid.uuid4()).upper(),
            "includedInGallery": True,
            "mediaPlate": MAT,
            "name": filename.replace("_landscape.png", ""),
            "overlays": [],
            "screenshotReference": ref,
            "screenshotTransform": {
                "blurRadius": 0, "offsetX": 0, "offsetY": 0,
                "rotationDegrees": 0, "scale": 0.97, "swivelDegrees": 0,
            },
        }}})

    doc = {
        "appStoreName": "100 Burfords",
        "exportPreset": PRESET,
        "items": items,
        "schemaVersion": 5,
        "style": STYLE,
        "critiqueGoal": (
            "Sell a weekly cartoon archive to Upper West Side readers who already "
            "know Martoonerville from the West Side Rag. Warm, neighborly, print-"
            "adjacent — the cartoon itself is the product, so it must be legible "
            "and never cropped."
        ),
    }
    with open(os.path.join(OUT, "project.json"), "w") as f:
        json.dump(doc, f, indent=2, ensure_ascii=False)
    print(f"wrote {os.path.basename(OUT)}: {len(items)} slides")


main()
