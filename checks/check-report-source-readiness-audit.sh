#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
base="$tmp/sample"
mkdir -p "$base"

cat >"$base/config.tsv" <<'EOF'
DEFAULT_CURRENCY	JPY
ACTUAL_JOURNAL_FILE	actual.journal
EOF
cat >"$base/accounts.tsv" <<'EOF'
assets:cash	currency=JPY	role=asset
expenses:food	role=expense
EOF
cat >"$base/plan.tsv" <<'EOF'
2026-01-02	food	assets:cash	expenses:food	10	currency=JPY	plan_id=p1
2026-01-03	food	assets:cash	expenses:food	20
EOF
cat >"$base/budget_alloc.tsv" <<'EOF'
2026-01-01	allocation	budget:unassigned	budget:food	30
EOF
: >"$base/actual.journal"

before=$(find "$base" -type f -exec shasum {} + | sort)
out=$(python3 tools/characterization/report_source_readiness_audit.py "$base")
after=$(find "$base" -type f -exec shasum {} + | sort)
[[ "$before" == "$after" ]]

grep -Fqx $'base\tdefault_currency\taccount_rows\taccount_currency_missing\taccount_role_missing\tplan_rows\tplan_currency_missing\tplan_id_missing\tbudget_rows\tbudget_currency_missing\tactual_layout' <<<"$out"
grep -Fq $'\texplicit\t2\t1\t0\t2\t1\t1\t1\t1\tdirect' <<<"$out"

summary=$(python3 tools/characterization/report_source_readiness_audit.py "$tmp" --children --summary)
grep -Fqx $'bases\t1' <<<"$summary"
grep -Fqx $'default_currency_not_explicit\t0' <<<"$summary"
grep -Fqx $'account_currency_missing\t1' <<<"$summary"
grep -Fqx $'plan_currency_missing\t1' <<<"$summary"
grep -Fqx $'plan_id_missing\t1' <<<"$summary"
grep -Fqx $'budget_currency_missing\t1' <<<"$summary"
grep -Fqx $'actual_nested_fallback\t0' <<<"$summary"

if python3 tools/characterization/report_source_readiness_audit.py "$tmp/missing" >/dev/null 2>&1; then
  echo "FAIL: missing audit path succeeded" >&2
  exit 1
fi

echo "check-report-source-readiness-audit: OK"
