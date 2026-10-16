#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../game"
godot --headless --import >/dev/null 2>&1 || true

# Selvtest (T-096): runneren skal fejle, når en testfil ikke kan parses.
tmp="selftest_tmp"
rm -rf "$tmp"; mkdir -p "$tmp"
cp tests/fixtures/broken_runner/test_broken.gd.txt "$tmp/test_broken.gd"
if godot --headless -s res://tests/framework/run_tests.gd -- --test-dir=res://$tmp >/dev/null 2>&1; then
	rm -rf "$tmp"
	echo "SELFTEST FAIL: run_tests.gd melder grønt for en testfil med parse-fejl" >&2
	exit 1
fi
rm -rf "$tmp"
echo "Runner-selvtest OK (parse-fejl giver rød)"

godot --headless -s res://tests/framework/run_tests.gd
