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

# T-072: ScenarioDef.list_all() i en eksporteret pck (Web-presetets filtre; DirAccess i pakken).
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
godot --headless --export-pack "Web" "$tmp/game.pck" >/dev/null 2>&1 || { echo "Integration: export-pack fejlede"; exit 1; }
chk="$PWD/tools/export_check.gd"
pck_out=$(cd "$tmp" && godot --headless --main-pack "$tmp/game.pck" -s "$chk" 2>&1) || { echo "$pck_out"; exit 1; }
echo "$pck_out" | grep export_check
echo "$pck_out" | grep -q "export_check: OK" || { echo "Integration: export_check fejlede"; exit 1; }
