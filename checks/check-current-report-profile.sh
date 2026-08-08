#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-current-profile.XXXXXX")
trap 'rm -rf "$work"' EXIT
cp -R "$fixture" "$work/base"
base="$work/base"

# Supply one prior realized income anchor and its exact reversal so the proof has
# two resolvable canonical income-anchor cycles without changing opening balances.
cat >>"$base/actual.journal" <<'EOF'

2025-12-01 prior income anchor
    ; event-id: current-profile-prior-income
    ; layer: actual
    ; currency: JPY
    assets:cash 1 JPY
    income:salary -1 JPY

2025-12-02 prior income neutralization
    ; event-id: current-profile-prior-neutralization
    ; layer: actual
    ; currency: JPY
    assets:cash -1 JPY
    income:salary 1 JPY
EOF

# Historical next-income Plan evidence closes the prior cycle at the realized
# 2026-01-02 anchor. The retained future Plan closes the current cycle.
cat >>"$base/plan.journal" <<'EOF'

2026-01-02 historical next income
    ; plan-id: current-profile-historical-income
    income:salary -1 JPY
    assets:cash 1 JPY
EOF

# Move Actual evidence one day beyond every concrete observation in the template.
cat >>"$base/actual.journal" <<'EOF'

2026-01-13 * next-day current-profile proof
    ; event-id: current-profile-next-day
    ; layer: actual
    ; currency: JPY
    expenses:transport 7 JPY
    assets:cash -7 JPY
EOF

./tools/report-current-manifest "$base" report_all_human.destination.tsv >"$work/current.tsv"
awk -F'\t' '$1=="balances" {exit !($4=="2026-01-13")}' "$work/current.tsv"
awk -F'\t' '$1=="profit-and-loss" {exit !($4=="2026-01-02" && $5=="2026-01-14")}' "$work/current.tsv"
awk -F'\t' '$1=="cycle-comparison" {exit !($4=="2026-01-13" && $5=="2025-12-12")}' "$work/current.tsv"
awk -F'\t' '$1=="monthly-accounts" {exit !($4=="2026-01" && $5=="2026-02")}' "$work/current.tsv"
awk -F'\t' '$1=="daily-flow" {exit !($3=="JPY" && $4=="2026-01-02" && $5=="2026-02-01" && $6=="2026-01-13")}' "$work/current.tsv"

./tools/report-all "$root" "$base" human "$work/current.tsv" >"$work/all.txt"
[[ $(grep -c '^== ' "$work/all.txt") -eq 12 ]]
grep -F 'As of: 2026-01-13 (JPY)' "$work/all.txt" >/dev/null
grep -F 'Period: 2026-01-02..2026-01-14 (JPY)' "$work/all.txt" >/dev/null

mkdir "$work/ui"
printf 'balance-sheet\n' | \
  TMPDIR="$work/ui" BL_SELECTOR=plain \
  ./tools/main-ui.sh --base "$base" --manifest-config "$base/report_manifests.destination.tsv" select \
  >"$work/ui.out" 2>"$work/ui.err"
grep -F 'As of: 2026-01-13 (JPY)' "$work/ui.out" >/dev/null

./tools/report "$base" balances human JPY 2026-01-12 actual.journal >"$work/historical.txt"
grep -F 'As of: 2026-01-12' "$work/historical.txt" >/dev/null

cache="$work/cache"
./tools/command-hub-cache-refresh "$base" "$cache" 1 "$work/current.tsv"
cp "$work/current.tsv" "$work/bad.tsv"
python3 - "$work/bad.tsv" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = "daily-flow\thuman\tJPY\t2026-01-02\t2026-02-01\t2026-01-13\tactual.journal"
new = "daily-flow\thuman\tJPY\t2026-01-02\t2026-02-01\t2026-01-12\tactual.journal"
if s.count(old) != 1:
    raise SystemExit("expected one current Daily Flow row")
p.write_text(s.replace(old, new))
PY
if ./tools/command-hub-cache-refresh "$base" "$cache" 2 "$work/bad.tsv"; then
  echo 'FAIL: stale-observation refresh succeeded' >&2
  exit 1
fi
grep -F 'observation_evidence_mismatch' "$cache/.cache-error" >/dev/null
./tools/command-hub-preview "$cache" balance-sheet >"$work/stale-preview.txt"
grep -F '前回正常生成時のpreview' "$work/stale-preview.txt" >/dev/null
grep -F 'observation_evidence_mismatch' "$work/stale-preview.txt" >/dev/null
grep -F '== Balance Sheet ==' "$work/stale-preview.txt" >/dev/null
[[ $(cat "$cache/.cache-timestamp") == 1 ]]

echo 'check-current-report-profile: OK'
