#!/bin/bash
# Screenshot helper: dev/shots.sh key1,key2 [days=N] [notch=PX] [club=ID]   (GODOT=path/to/godot, default "godot")
# Saves PNGs to /tmp/shots and prints any script errors. Tile them with: python3 dev/sheet.py out.png [files...]
cd "$(dirname "$0")/.."
rm -rf /tmp/shots
xvfb-run -a -s "-screen 0 1380x620x24" "${GODOT:-godot}" --path . --audio-driver Dummy --rendering-driver opengl3 --resolution 1380x620 -- --shots only=$1 "${@:2}" 2>&1 | grep -i -E "error|invalid|backtrace|\[[0-9]\]" | head -30
ls /tmp/shots 2>/dev/null
