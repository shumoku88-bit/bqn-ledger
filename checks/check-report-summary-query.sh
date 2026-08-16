#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-summary.XXXXXX")
trap 'rm -rf "$work"' EXIT

Compare() {
  local actual=$1 expected=$2 label=$3
  cmp "$actual" "$expected" || {
    echo "FAIL: $label" >&2
    diff -u "$expected" "$actual" >&2 || true
    exit 1
  }
}

./tools/report-summary "$fixture" JPY 2026-01-12 >"$work/summary"
Compare "$work/summary" "$fixture/report_summary.destination.txt" 'canonical compact summary mismatch'
if rg -n 'src_next_|SrcNext|src-next' "$work/summary"; then
  echo 'FAIL: generation name leaked into destination summary' >&2; exit 1
fi
[[ $(grep -c '^--- Ledger ' "$work/summary") -eq 5 ]]
awk -F': ' '$1 ~ /^ledger_[a-z0-9_]+$/ {print}' "$work/summary" >"$work/ledger-lines"
./tools/query "$fixture" JPY --list 2026-01-12 >"$work/query-list"
Compare "$work/query-list" "$work/ledger-lines" 'query --list differs from canonical compact summary'
awk -F': ' '$1 ~ /^ledger_[a-z0-9_]+$/ && !seen[$1]++ {print $1}' "$work/summary" >"$work/keys"
./tools/query "$fixture" JPY --keys 2026-01-12 >"$work/query-keys"
Compare "$work/query-keys" "$work/keys" 'query --keys differs from canonical compact summary'
printf '%s\n' \
  'assets:cash/JPY 965' \
  'income:salary/JPY -1000' \
  'expenses:food/JPY 30' \
  'expenses:transport/JPY 5' \
  'budget:opening/JPY 0' \
  'budget:unassigned/JPY 0' \
  'budget:food/JPY 0' >"$work/expected-balances"
./tools/query "$fixture" JPY ledger_balance 2026-01-12 >"$work/balances"
Compare "$work/balances" "$work/expected-balances" 'ledger_balance query mismatch'
./tools/query "$fixture" JPY ledger_daily_target_amount 2026-01-12 >"$work/daily-target"
[[ -s $work/daily-target ]]

# Exact lookup: no prefix matching, old-key translation, regex query surface.
for key in ledger_bal ledger_balance_extra src_next_balance; do
  if ./tools/query "$fixture" JPY "$key" 2026-01-12 >"$work/rejected.out" 2>"$work/rejected.err"; then
    echo "FAIL: rejected query succeeded: $key" >&2; exit 1
  fi
  [[ ! -s $work/rejected.out ]]
done
if ./tools/query "$fixture" JPY --grep 2026-01-12 >"$work/rejected.out" 2>"$work/rejected.err"; then
  echo 'FAIL: regex query surface succeeded' >&2; exit 1
fi
[[ ! -s $work/rejected.out ]]

# Invalid canonical Report policy never publishes a successful compact prefix.
cp -R "$fixture" "$work/bad-base"
python3 - "$work/bad-base/report.toml" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = "count = 5"
if s.count(old) != 1:
    raise SystemExit("expected one recent count")
p.write_text(s.replace(old, "count = 0"))
PY
if ./tools/report-summary "$work/bad-base" JPY 2026-01-12 >"$work/bad.out" 2>"$work/bad.err"; then
  echo 'FAIL: invalid canonical Report policy summary succeeded' >&2; exit 1
fi
[[ ! -s $work/bad.out ]]
grep -F 'report_policy_positive_integer_invalid' "$work/bad.err" >/dev/null

(
  cd "$work"
  "$root/tools/report-summary" "$root/$fixture" JPY 2026-01-12 >from-empty-cwd
)
Compare "$work/from-empty-cwd" "$work/summary" 'empty-cwd compact summary mismatch'

echo 'check-report-summary-query: OK'
