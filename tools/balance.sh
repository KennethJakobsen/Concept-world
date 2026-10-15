#!/usr/bin/env bash
# Balance-simulation: scriptet startpark i 5 dage (T-024).
set -euo pipefail
cd "$(dirname "$0")/../game"
godot --headless --import >/dev/null 2>&1 || true
godot --headless -s res://tools/balance_sim.gd
