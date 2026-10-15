#!/usr/bin/env bash
# Balance-simulation: scenarier à 5 dage + T-041 sammenligning 7 dage m/u personale.
set -euo pipefail
cd "$(dirname "$0")/../game"
godot --headless --import >/dev/null 2>&1 || true
godot --headless -s res://tools/balance_sim.gd
