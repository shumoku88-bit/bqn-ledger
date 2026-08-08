#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-household-cutover.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

# This root intentionally contains only canonical evidence needed by these reads.
cp "$fixture/accounts.journal" "$fixture/actual.journal" "$fixture/plan.journal" \
  "$fixture/budget.journal" "$fixture/budget.toml" "$fixture/household.toml" "$tmp/"

for legacy in accounts.tsv cycle.tsv daily_target_scope.tsv budget_alloc.tsv config.tsv; do
  [[ ! -e "$tmp/$legacy" ]] || { echo "FAIL: legacy source leaked into canonical-only root: $legacy" >&2; exit 1; }
done

# Path-shaped garbage in legacy argv coordinates must not redirect physical I/O.
./tools/report "$tmp" envelopes human JPY \
  2026-01-01 2026-02-01 2026-01-12 actual.journal bad/plan.tsv bad/budget.tsv bad/funding \
  >"$tmp/envelopes.out"
grep -F '== Envelope & Backing Statement ==' "$tmp/envelopes.out" >/dev/null

./tools/report "$tmp" cycle-accounts human JPY \
  2026-01-12 actual.journal bad/cycle.tsv bad/plan.tsv >"$tmp/cycle.out"
grep -F '== Cycle Accounts ==' "$tmp/cycle.out" >/dev/null

./tools/report "$tmp" planned human \
  2026-01-12 actual.journal bad/plan.tsv bad/cycle.tsv >"$tmp/planned.out"
grep -F '== Planned Payments ==' "$tmp/planned.out" >/dev/null

./tools/report "$tmp" daily-target human JPY \
  2026-01-12 2026-01-22 actual.journal bad/plan.tsv bad/daily_target_scope.tsv >"$tmp/daily.out"
grep -F '== Daily Target ==' "$tmp/daily.out" >/dev/null

echo 'check-canonical-household-read-cutover: OK'
