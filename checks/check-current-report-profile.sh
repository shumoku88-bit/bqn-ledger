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

cat >>"$base/plan.journal" <<'EOF'

2026-01-02 historical next income
    ; plan-id: current-profile-historical-income
    income:salary -1 JPY
    assets:cash 1 JPY
EOF

cat >>"$base/actual.journal" <<'EOF'

2026-01-13 * next-day current-profile proof
    ; event-id: current-profile-next-day
    ; layer: actual
    ; currency: JPY
    expenses:transport 7 JPY
    assets:cash -7 JPY
EOF

bqn src/application/current_report_profile_cli.bqn "$base" JPY human 2026-01-13 >"$work/current.tsv"
awk -F'\t' '$1=="balances" {exit !($3=="JPY" && $4=="2026-01-13")}' "$work/current.tsv"
awk -F'\t' '$1=="profit-and-loss" {exit !($3=="JPY" && $4=="2026-01-01" && $5=="2026-01-14")}' "$work/current.tsv"
awk -F'\t' '$1=="cycle-comparison" {exit !($3=="JPY" && $4=="2026-01-13" && $5=="2025-12-12")}' "$work/current.tsv"
awk -F'\t' '$1=="monthly-accounts" {exit !($3=="JPY" && $4=="2026-01" && $5=="2026-02")}' "$work/current.tsv"
awk -F'\t' '$1=="daily-flow" {exit !($3=="JPY" && $4=="2026-01-01" && $5=="2026-01-14" && $6=="2026-01-13")}' "$work/current.tsv"

./tools/report-all "$base" JPY human 2026-01-13 >"$work/all.txt"
[[ $(grep -c '^== ' "$work/all.txt") -eq 12 ]]
grep -F 'As of: 2026-01-13 (JPY)' "$work/all.txt" >/dev/null
grep -F 'Period: 2026-01-01..2026-01-14 (JPY)' "$work/all.txt" >/dev/null

mkdir "$work/ui"
printf 'balance-sheet\n' | \
  TMPDIR="$work/ui" BL_SELECTOR=plain COMMAND_HUB_CACHE_REFRESH_MODE=synchronous \
  ./tools/main-ui.sh --base "$base" --domain JPY --latest 2026-01-13 select \
  >"$work/ui.out" 2>"$work/ui.err"
grep -F 'As of: 2026-01-13 (JPY)' "$work/ui.out" >/dev/null

./tools/report "$base" balances human JPY 2026-01-12 >"$work/historical.txt"
grep -F 'As of: 2026-01-12' "$work/historical.txt" >/dev/null

cache="$work/cache"
./tools/command-hub-cache-refresh "$base" "$cache" 1 JPY 2026-01-13
cp "$base/report.toml" "$work/report.toml.good"
python3 - "$base/report.toml" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = "count = 5"
new = "count = 0"
if s.count(old) != 1:
    raise SystemExit("expected one recent count")
p.write_text(s.replace(old, new))
PY
if ./tools/command-hub-cache-refresh "$base" "$cache" 2 JPY 2026-01-13; then
  echo 'FAIL: invalid canonical Report policy refresh succeeded' >&2
  exit 1
fi
grep -F 'report_policy_positive_integer_invalid' "$cache/.cache-error" >/dev/null
./tools/command-hub-preview "$cache" balance-sheet >"$work/stale-preview.txt"
grep -F '前回正常生成時のpreview' "$work/stale-preview.txt" >/dev/null
grep -F 'report_policy_positive_integer_invalid' "$work/stale-preview.txt" >/dev/null
grep -F '== Balance Sheet ==' "$work/stale-preview.txt" >/dev/null
[[ $(cat "$cache/.cache-timestamp") == 1 ]]

echo 'check-current-report-profile: OK'
