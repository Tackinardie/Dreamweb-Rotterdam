#!/bin/sh
# gebruik: ./run.sh a|b <cam> <uitvoernaam.png>
cd "$(dirname "$0")"
scene=$([ "$1" = b ] && echo res://b_kamer.tscn || echo res://a_straat.tscn)
godot --path . --resolution 1920x1080 --windowed "$scene" -- --cam=$2 --shot=shots/$3 --frames=${4:-200}
