#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$project_dir/builds"

if command -v godot >/dev/null 2>&1; then
  godot --headless --path "$project_dir" --export-debug Android "$project_dir/builds/empire-legacy-debug.apk"
elif command -v godot4 >/dev/null 2>&1; then
  godot4 --headless --path "$project_dir" --export-debug Android "$project_dir/builds/empire-legacy-debug.apk"
else
  echo "Godot 4 was not found. Install Godot and its Android export templates first." >&2
  exit 1
fi

echo "APK created at: $project_dir/builds/empire-legacy-debug.apk"

