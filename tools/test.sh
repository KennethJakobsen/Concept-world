#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../game"
godot --headless --import >/dev/null 2>&1 || true
godot --headless -s res://tests/framework/run_tests.gd
