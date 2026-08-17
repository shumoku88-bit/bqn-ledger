#!/usr/bin/env bash
set -euo pipefail
trap 'status=$?; echo "FAIL: check-canonical-household-read-cutover line $LINENO" >&2; echo "::error file=checks/check-canonical-household-read-cutover.sh,line=$LINENO::canonical Household cutover check failed" >&2; exit "$status"' ERR

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-household-cutover.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

# Exactly the canonical Household source topology is sufficient for retained reads.
cp "$fixture/accounts.journal" "$fixture/actual.journal" "$fixture/plan.journal" \
  "$fixture/entitlement.journal" "$fixture/envelope.toml" "$fixture/household.toml" \
  "$fixture/report.toml" "$fixture/issues.tsv" "$tmp/"

expected=(accounts.journal actual.journal plan.journal entitlement.journal envelope.toml household.toml report.toml issues.tsv)
for name in "${expected[@]}"; do [[ -f "$tmp/$name" ]] || { echo "FAIL: canonical source missing: $name" >&2; exit 1; }; done
for legacy in accounts.tsv cycle.tsv daily_target_scope.tsv budget_alloc.tsv config.tsv plan.tsv budget.journal budget.toml report_manifests.tsv report_all_human.tsv report_all_compact.tsv; do
  [[ ! -e "$tmp/$legacy" ]] || { echo "FAIL: legacy source leaked into canonical-only root: $legacy" >&2; exit 1; }
done

./tools/report "$tmp" envelopes human JPY 2026-01-01 2026-02-01 2026-01-12 >"$tmp/envelopes.out"
grep -F '== Envelope & Backing ==' "$tmp/envelopes.out" >/dev/null
./tools/report "$tmp" cycle-accounts human JPY 2026-01-12 >"$tmp/cycle.out"
grep -F '== Current-cycle Accounts ==' "$tmp/cycle.out" >/dev/null
./tools/report "$tmp" planned human 2026-01-12 >"$tmp/planned.out"
grep -F '== Planned Payments ==' "$tmp/planned.out" >/dev/null
./tools/report "$tmp" daily-flow human JPY 2026-01-01 2026-02-01 2026-01-12 >"$tmp/daily-flow.out"
grep -F '== Daily Flow ==' "$tmp/daily-flow.out" >/dev/null
./tools/report "$tmp" daily-target human JPY 2026-01-12 2026-01-22 >"$tmp/daily.out"
grep -F '== Daily Target ==' "$tmp/daily.out" >/dev/null
./tools/report "$tmp" issues human >"$tmp/issues.out"
grep -F '== Issues ==' "$tmp/issues.out" >/dev/null

if ./tools/report "$tmp" balances human JPY 2026-01-12 actual.journal >"$tmp/physical.out" 2>&1; then
  echo 'FAIL: physical source coordinate survived canonical cutover' >&2
  exit 1
fi
grep -F 'usage_balances' "$tmp/physical.out" >/dev/null

echo 'check-canonical-household-read-cutover: OK'
