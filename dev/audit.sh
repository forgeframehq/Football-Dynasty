#!/bin/bash
# Game check: dev/audit.sh [days=N] [notch=PX]   (GODOT=path/to/godot). Report in /tmp/audit.txt
cd "$(dirname "$0")/.."
xvfb-run -a -s "-screen 0 1380x620x24" "${GODOT:-godot}" --path . --audio-driver Dummy --rendering-driver opengl3 --resolution 1380x620 -- --audit "$@" > /tmp/audit_raw.txt 2>&1
grep -E "^AUDIT|SCRIPT ERROR|Parse Error" -A2 /tmp/audit_raw.txt | grep -v "^--" | cut -c1-900
