#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../game"
mkdir -p ../build/web
godot --headless --import >/dev/null 2>&1 || true
godot --headless --export-release "Web" ../build/web/index.html
echo "Web build: build/web/ (serve: python3 -m http.server -d build/web 8000)"
