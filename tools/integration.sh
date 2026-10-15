#!/usr/bin/env bash
# T-041: headless integrationstest af hovedmenu → park → gem → indlæs (rigtige scene-skift).
set -euo pipefail
cd "$(dirname "$0")/../game"
godot --headless --import >/dev/null 2>&1 || true
out=$(godot --headless -s res://tools/integration_flow.gd 2>&1) || { echo "$out"; exit 1; }
echo "$out"
if echo "$out" | grep -E "SCRIPT ERROR|^ERROR|WARNING" >/dev/null; then
	echo "Integration: fejl/advarsler i output"; exit 1
fi
