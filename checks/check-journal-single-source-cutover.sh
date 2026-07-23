#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
base="$tmp/base"
mkdir -p "$base"
fixture=fixtures/journal-file-backed-shadow-context
cp "$fixture/cycle.tsv" "$fixture/plan.tsv" "$fixture/budget_alloc.tsv" "$base/"
# Registry parity must compare account values, not declaration/source row order.
{
  grep '^#' "$fixture/accounts.tsv"
  grep -vE '^(#|$)' "$fixture/accounts.tsv" | LC_ALL=C sort
} >"$base/accounts.tsv"
cp "$fixture/shadow.journal" "$base/actual.journal"
awk '
  /^ACTUAL_SOURCE=/ {print "ACTUAL_SOURCE=journal"; next}
  /^ACTUAL_JOURNAL_FILE=/ {print "ACTUAL_JOURNAL_FILE=actual.journal"; next}
  {print}
  END {print "DEFAULT_CURRENCY=JPY"}
' config/default_config.tsv >"$base/config.tsv"

[[ ! -e "$base/journal.tsv" ]]
report_out="$tmp/report.out"
tools/report "$base" >"$report_out"
[[ -s "$report_out" && ! -e "$base/journal.tsv" ]]

before_sha=$(shasum -a 256 "$base/actual.journal" | awk '{print $1}')
before_event_count=$(grep -Fc '; event-id:' "$base/actual.journal" || true)
before_layer_count=$(grep -Fc '; layer: actual' "$base/actual.journal" || true)
before_currency_count=$(grep -Fc '; currency: JPY' "$base/actual.journal" || true)

daily_out="$tmp/daily.out"
tools/edit --base "$base" journal add --date 2026-08-05 --memo 'Journal-only daily add' --from assets:cash --to expenses:food --amount 25 --currency JPY --yes >"$daily_out"

after_sha=$(shasum -a 256 "$base/actual.journal" | awk '{print $1}')
after_event_count=$(grep -Fc '; event-id:' "$base/actual.journal" || true)
after_layer_count=$(grep -Fc '; layer: actual' "$base/actual.journal" || true)
after_currency_count=$(grep -Fc '; currency: JPY' "$base/actual.journal" || true)

[[ "$before_sha" != "$after_sha" && ! -e "$base/journal.tsv" ]]
[[ "$after_event_count" -eq "$before_event_count" ]]
[[ "$after_layer_count" -eq "$before_layer_count" ]]
[[ "$after_currency_count" -eq "$before_currency_count" ]]
grep -Fq '2026-08-05 * Journal-only daily add' "$base/actual.journal"
grep -Fq '    expenses:food    25 JPY' "$base/actual.journal"
grep -Fq '    assets:cash    -25 JPY' "$base/actual.journal"
grep -Fq 'Mandatory native validation: OK' "$daily_out"
grep -Fq $'OK\tNATIVE_JOURNAL_CANDIDATE\tordinary\t-' "$daily_out"
! grep -Fq 'entry-' "$daily_out"
! grep -Fq 'stage0-line-' "$daily_out"
[[ "$(tools/edit --base "$base" journal list --format tsv | wc -l | tr -d ' ')" -eq 3 ]]

daily_event_count="$after_event_count"
tools/edit --base "$base" plan add --date 2026-08-20 --memo 'Journal-only plan completion' --from assets:cash --to expenses:household --amount 40 --id plan-2026-08-20-journal-cutover --yes
plan_finish_out="$tmp/plan-finish.out"
tools/edit --base "$base" plan finish --id plan-2026-08-20-journal-cutover --actual-date 2026-07-23 --apply --yes >"$plan_finish_out"
[[ ! -e "$base/journal.tsv" ]]
plan_event_count=$(grep -Fc '; event-id:' "$base/actual.journal" || true)
[[ "$plan_event_count" -eq $((daily_event_count + 1)) ]]
grep -Fq '    ; event-id: completion-plan-2026-08-20-journal-cutover-2026-07-23' "$base/actual.journal"
grep -Fq '    ; plan-id: plan-2026-08-20-journal-cutover' "$base/actual.journal"
grep -Fq $'OK\tNATIVE_JOURNAL_CANDIDATE\tdurable\tcompletion-plan-2026-08-20-journal-cutover-2026-07-23' "$plan_finish_out"
tools/edit --base "$base" plan list --all --format tsv | grep -Fq $'plan-2026-08-20-journal-cutover\t2026-08-20'

tools/report "$base" >"$report_out"
[[ -s "$report_out" && ! -e "$base/journal.tsv" ]]
echo 'OK: Journal-only report, daily add, list, and plan completion passed without journal.tsv'
