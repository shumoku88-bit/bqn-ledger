#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
manifest="$fixture/report_all_compact.destination.tsv"
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-summary.XXXXXX")
trap 'rm -rf "$work"' EXIT

./tools/report-summary "$fixture" "$manifest" >"$work/summary"
cmp "$work/summary" "$fixture/report_summary.destination.txt"
if rg -n 'src_next_|SrcNext|src-next' "$work/summary"; then
  echo 'FAIL: generation name leaked into destination summary' >&2; exit 1
fi
[[ $(grep -c '^--- Ledger ' "$work/summary") -eq 5 ]]
awk -F': ' '$1 ~ /^ledger_[a-z0-9_]+$/ {print}' "$work/summary" >"$work/ledger-lines"
./tools/query "$fixture" "$manifest" --list >"$work/query-list"
cmp "$work/ledger-lines" "$work/query-list"
awk -F': ' '$1 ~ /^ledger_[a-z0-9_]+$/ && !seen[$1]++ {print $1}' "$work/summary" >"$work/keys"
./tools/query "$fixture" "$manifest" --keys >"$work/query-keys"
cmp "$work/keys" "$work/query-keys"
printf '%s\n' \
  'assets:cash/JPY 965' \
  'income:salary/JPY -1000' \
  'expenses:food/JPY 30' \
  'expenses:transport/JPY 5' \
  'budget:opening/JPY 0' \
  'budget:unassigned/JPY 0' \
  'budget:food/JPY 0' \
  'budget:spent/JPY 0' >"$work/expected-balances"
./tools/query "$fixture" "$manifest" ledger_balance >"$work/balances"
cmp "$work/expected-balances" "$work/balances"
[[ $(./tools/query "$fixture" "$manifest" ledger_daily_target_amount) == 81 ]]

# Exact lookup: no prefix matching, old-key translation, or regex query surface.
for key in ledger_bal ledger_balance_extra src_next_balance; do
  if ./tools/query "$fixture" "$manifest" "$key" >"$work/rejected.out" 2>"$work/rejected.err"; then
    echo "FAIL: rejected query succeeded: $key" >&2; exit 1
  fi
  [[ ! -s $work/rejected.out ]]
done
if ./tools/query "$fixture" "$manifest" --grep balance >"$work/rejected.out" 2>"$work/rejected.err"; then
  echo 'FAIL: regex query surface succeeded' >&2; exit 1
fi
[[ ! -s $work/rejected.out ]]

# Summary admits the complete manifest and never publishes a successful prefix.
cp "$manifest" "$work/bad.tsv"
printf 'unknown\tcompact\tbad\n' >>"$work/bad.tsv"
if ./tools/report-summary "$fixture" "$work/bad.tsv" >"$work/bad.out" 2>"$work/bad.err"; then
  echo 'FAIL: malformed summary manifest succeeded' >&2; exit 1
fi
[[ ! -s $work/bad.out ]]
grep -F 'all_manifest_count_mismatch' "$work/bad.err" >/dev/null

(
  cd "$work"
  "$root/tools/report-summary" "$root/$fixture" "$root/$manifest" >from-empty-cwd
)
cmp "$work/from-empty-cwd" "$work/summary"

echo 'check-report-summary-query: OK'
