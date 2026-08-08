#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture="$root/fixtures/ledger-facts-phase1-proof"

output="$(LEDGER_DATA_DIR="$fixture" NO_COLOR=1 "$root/tools/doctor")"
printf '%s\n' "$output" | grep -F 'PASS canonical Household root files present: 8' >/dev/null
printf '%s\n' "$output" | grep -F 'PASS canonical Actual and Report policy admission succeeded' >/dev/null

if grep -Eq 'accounts\.tsv|plan\.tsv|budget_alloc\.tsv|cycle\.tsv|daily_target_scope\.tsv|config\.tsv|src_edit/' "$root/tools/doctor"; then
  echo 'FAIL: doctor still depends on a legacy Household source or writer-side command' >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

missing="$tmp/missing"
mkdir -p "$missing"
cp -R "$fixture"/. "$missing"/
rm "$missing/report.toml"
if LEDGER_DATA_DIR="$missing" NO_COLOR=1 "$root/tools/doctor" >"$tmp/missing.out" 2>&1; then
  echo 'FAIL: doctor accepted a Household root without report.toml' >&2
  exit 1
fi
grep -F 'missing canonical Household file(s): report.toml' "$tmp/missing.out" >/dev/null

invalid="$tmp/invalid"
mkdir -p "$invalid"
cp -R "$fixture"/. "$invalid"/
printf '[query]\nunknown = "value"\n' >"$invalid/report.toml"
if LEDGER_DATA_DIR="$invalid" NO_COLOR=1 "$root/tools/doctor" >"$tmp/invalid.out" 2>&1; then
  echo 'FAIL: doctor accepted invalid canonical Report policy' >&2
  exit 1
fi
grep -F 'canonical Actual or Report policy admission failed' "$tmp/invalid.out" >/dev/null

echo OK
