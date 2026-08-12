#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-cache-proof.XXXXXX")
trap 'rm -rf "$work"' EXIT

selection_cli=src/application/report_selection_cli.bqn
grep -Fq 'request ← •Import "../report/request.bqn"' "$selection_cli"
if grep -Eq '•Import ".*(source_adapter|source_io|canonical_household_sources)' "$selection_cli"; then
  echo 'FAIL: Report selection CLI gained source ownership' >&2
  exit 1
fi

cp -R "$fixture" "$work/base"
base="$work/base"
cache="$work/cache"
mkdir "$cache"

cat >>"$base/actual.journal" <<'EOF'

2025-12-01 cache prior income anchor
    ; event-id: cache-prior-income
    ; layer: actual
    ; currency: JPY
    assets:cash 1 JPY
    income:salary -1 JPY

2025-12-02 cache prior income neutralization
    ; event-id: cache-prior-neutralization
    ; layer: actual
    ; currency: JPY
    assets:cash -1 JPY
    income:salary 1 JPY
EOF
cat >>"$base/plan.journal" <<'EOF'

2026-01-02 cache historical next income
    ; plan-id: cache-historical-income
    income:salary -1 JPY
    assets:cash 1 JPY
EOF

printf 'retired\n' >"$cache/snapshot.txt"
printf 'retired\n' >"$cache/debug.txt"
printf 'keep\n' >"$cache/application.note"

./tools/report-cache "$base" "$cache" 101 JPY 2026-01-12
mapfile -t expected < <(bqn src/application/report_selection_cli.bqn all human)
printf '%s\n' "${expected[@]}" all >"$work/expected-keys"
cmp "$work/expected-keys" "$cache/.section-keys"
[[ $(cat "$cache/.cache-timestamp") == 101 ]]
[[ ! -e $cache/snapshot.txt && ! -e $cache/debug.txt && -e $cache/application.note ]]
for key in "${expected[@]}" all; do [[ -f $cache/$key.txt ]]; done
text_count=$(find "$cache" -maxdepth 1 -type f -name '*.txt' | wc -l | tr -d ' ')
[[ $text_count -eq $((${#expected[@]} + 1)) ]]

./tools/report-all "$base" JPY human 2026-01-12 >"$work/direct-all"
cmp "$work/direct-all" "$cache/all.txt"
./tools/report "$base" balances human JPY 2026-01-12 >"$work/direct-balances"
cmp "$work/direct-balances" "$cache/balances.txt"
: >"$work/concatenated"
for key in "${expected[@]}"; do cat "$cache/$key.txt" >>"$work/concatenated"; done
cmp "$work/concatenated" "$cache/all.txt"

all_hash=$(shasum -a 256 "$cache/all.txt" | awk '{print $1}')
mkdir "$cache/.destination-cache-lock"
printf '%s\n' "$$" >"$cache/.destination-cache-lock/pid"
if ./tools/report-cache "$base" "$cache" 102 JPY 2026-01-12 >"$work/lock.out" 2>"$work/lock.err"; then
  echo 'FAIL: concurrent cache refresh succeeded' >&2; exit 1
fi
grep -F 'cache_refresh_locked' "$work/lock.err" >/dev/null
rm -rf "$cache/.destination-cache-lock"
[[ $(cat "$cache/.cache-timestamp") == 101 ]]

cp "$base/report.toml" "$work/report.toml.good"
python3 - "$base/report.toml" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
if s.count("count = 5") != 1:
    raise SystemExit("expected one recent count")
p.write_text(s.replace("count = 5", "count = 0"))
PY
if ./tools/report-cache "$base" "$cache" 102 JPY 2026-01-12 >"$work/bad.out" 2>"$work/bad.err"; then
  echo 'FAIL: invalid canonical Report policy cache refresh succeeded' >&2; exit 1
fi
grep -F 'report_policy_positive_integer_invalid' "$work/bad.err" >/dev/null
[[ $(cat "$cache/.cache-timestamp") == 101 ]]
[[ $(shasum -a 256 "$cache/all.txt" | awk '{print $1}') == "$all_hash" ]]
cp "$work/report.toml.good" "$base/report.toml"

if ./tools/report-cache "$base" "$cache" invalid JPY 2026-01-12 >"$work/token.out" 2>"$work/token.err"; then
  echo 'FAIL: invalid generation token succeeded' >&2; exit 1
fi
grep -F 'cache_generation_invalid' "$work/token.err" >/dev/null
[[ -z $(find "$cache" -maxdepth 1 -type d -name '.destination-stage.*' -print -quit) ]]

echo 'check-report-cache: OK'
