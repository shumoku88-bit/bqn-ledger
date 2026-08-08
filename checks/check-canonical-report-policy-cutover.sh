#!/usr/bin/env bash
set -euo pipefail
trap 'status=$?; echo "FAIL: check-canonical-report-policy-cutover line $LINENO" >&2; echo "::error file=checks/check-canonical-report-policy-cutover.sh,line=$LINENO::canonical Report policy cutover failed" >&2; exit "$status"' ERR

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-report-policy-cutover.XXXXXX")
trap 'rm -rf "$work"' EXIT
base="$work/root"
mkdir "$base"

canonical=(accounts.journal actual.journal plan.journal budget.journal budget.toml household.toml report.toml issues.tsv)
for name in "${canonical[@]}"; do cp "$fixture/$name" "$base/$name"; done

# Add only canonical evidence required to make Cycle Comparison observable in the
# all-human request set. No extra source file is introduced.
cat >>"$base/actual.journal" <<'EOF'

2025-12-01 Report cutover prior income anchor
    ; event-id: report-cutover-prior-income
    ; layer: actual
    ; currency: JPY
    assets:cash 1 JPY
    income:salary -1 JPY

2025-12-02 Report cutover prior income neutralization
    ; event-id: report-cutover-prior-neutralization
    ; layer: actual
    ; currency: JPY
    assets:cash -1 JPY
    income:salary 1 JPY

2026-01-13 Report cutover observation
    ; event-id: report-cutover-observation
    ; layer: actual
    ; currency: JPY
    expenses:transport 7 JPY
    assets:cash -7 JPY
EOF
cat >>"$base/plan.journal" <<'EOF'

2026-01-02 Report cutover historical next income
    ; plan-id: report-cutover-historical-income
    income:salary -1 JPY
    assets:cash 1 JPY
EOF

mapfile -t names < <(find "$base" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null || find "$base" -maxdepth 1 -type f -exec basename {} \;)
[[ ${#names[@]} -eq 8 ]] || { echo "FAIL: canonical Report proof root does not contain exactly eight files" >&2; printf '%s\n' "${names[@]}" >&2; exit 1; }
for name in "${canonical[@]}"; do [[ -f "$base/$name" ]]; done
for legacy in accounts.tsv plan.tsv budget_alloc.tsv cycle.tsv daily_target_scope.tsv config.tsv report_manifests.tsv report_all_human.tsv report_all_compact.tsv; do
  [[ ! -e "$base/$legacy" ]] || { echo "FAIL: legacy Report input exists in canonical proof root: $legacy" >&2; exit 1; }
done

bqn src/application/current_report_profile_cli.bqn "$base" JPY human 2026-01-13 >"$work/current.tsv"
[[ $(tail -n +2 "$work/current.tsv" | wc -l | tr -d ' ') -eq 12 ]]
if grep -Eq '(^|\t)(actual\.journal|plan\.journal|budget\.journal|issues\.tsv|.*\.tsv)(\t|$)' "$work/current.tsv"; then
  echo 'FAIL: generated current Report requests contain physical source coordinates' >&2
  cat "$work/current.tsv" >&2
  exit 1
fi

./tools/report-all "$base" JPY human 2026-01-13 >"$work/all-human"
[[ $(grep -c '^== ' "$work/all-human") -eq 12 ]]
./tools/report-summary "$base" JPY 2026-01-13 >"$work/all-compact"
[[ $(grep -c '^--- Ledger ' "$work/all-compact") -eq 5 ]]
./tools/main-ui.sh --base "$base" --domain JPY --latest 2026-01-13 report >"$work/ui-all"
[[ $(grep -c '^== ' "$work/ui-all") -eq 12 ]]

if ./tools/report "$base" balances human JPY 2026-01-13 actual.journal >"$work/physical" 2>&1; then
  echo 'FAIL: physical source coordinate remains accepted by Report CLI' >&2
  exit 1
fi
grep -F 'usage_balances' "$work/physical" >/dev/null

production=(
  src/application/report_route.bqn src/application/report_destination_cli.bqn
  src/application/current_report_profile_cli.bqn src/application/current_report_requests.bqn
  tools/report tools/report-all tools/report-cache tools/report-summary tools/query
  tools/main-ui.sh tools/command-hub-cache-refresh
)
if rg -n 'REPORT_MANIFEST_CONFIG|report_manifests\.tsv|report_all_human\.tsv|report_all_compact\.tsv|accounts\.tsv|plan\.tsv|budget_alloc\.tsv|cycle\.tsv|daily_target_scope\.tsv|config\.tsv' "${production[@]}"; then
  echo 'FAIL: production Report path still names a retired source topology' >&2
  exit 1
fi

echo 'check-canonical-report-policy-cutover: OK'
