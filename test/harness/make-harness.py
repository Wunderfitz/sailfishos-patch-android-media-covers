#!/usr/bin/env python3
"""Builds a runnable QML harness from the patched SwitcherItem.qml.

SwitcherItem itself only runs inside lipstick, so this copies the patch's own
blocks - each starts with a "// android-media-covers:" comment at the item's
top level - verbatim into a stand-in tile (Tile.qml.in) and puts a scenario
around it:

    make-harness.py <patched SwitcherItem.qml> <scenario.qml> > Harness.qml

Tile.qml.in provides what the blocks use from SwitcherItem: launcherItem,
running, windowPixmap, coverActionModel and loader, the latter with the same
sourceComponent expression as the patch. The scenario is placed inside the
harness's root item and gets the tile as the component "tile".
"""

import os
import sys

MARKER = "    // android-media-covers:"


def patch_blocks(lines):
    blocks = []
    i = 0
    while i < len(lines):
        if not lines[i].startswith(MARKER):
            i += 1
            continue
        start = i
        while lines[i].startswith("    //"):
            i += 1
        if lines[i].startswith("    readonly property"):
            # a run of properties ends at the first blank line
            while i < len(lines) and lines[i].strip():
                i += 1
        else:
            # an item ends at its closing brace at the top level
            while lines[i] != "    }\n":
                i += 1
            i += 1
        blocks.append("".join(lines[start:i]))
    return blocks


def main():
    patched, scenario = sys.argv[1:3]
    with open(patched) as f:
        blocks = patch_blocks(f.readlines())
    if len(blocks) != 4:
        sys.exit("expected 4 patch blocks, found %d" % len(blocks))
    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(here, "Tile.qml.in")) as f:
        template = f.read()
    with open(scenario) as f:
        scenario_text = f.read()
    tile = template.replace("%BLOCKS%", "\n".join(blocks))
    sys.stdout.write(tile.replace("%SCENARIO%", scenario_text))


main()
