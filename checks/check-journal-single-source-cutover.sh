#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if git grep -n -E 'ACTUAL_SOURCE|DEFAULT_JOURNAL_FILE|journal_source_(integrity|check)' -- src_edit src_next tools mcp-server config data >"$tmp/retired-symbols"; then
  echo 'FAIL: retired Actual TSV routing symbol remains in runtime/config' >&2
  cat "$tmp/retired-symbols" >&2
  exit 1
fi
if find data fixtures -name journal.tsv -print -quit | grep -q .; then
  echo 'FAIL: active sandbox/fixture journal.tsv remains' >&2
  exit 1
fi
base="$tmp/base"
mkdir -p "$base"
fixture=fixtures/src-next-golden
cp "$fixture/cycle.tsv" "$fixture/plan.tsv" "$fixture/accounts.tsv" "$fixture/actual.journal" "$base/"
: >"$base/budget_alloc.tsv"
awk '
  /^ACTUAL_JOURNAL_FILE=/ {print "ACTUAL_JOURNAL_FILE=actual.journal"; next}
  {print}
  END {print "DEFAULT_CURRENCY=JPY"}
' config/default_config.tsv >"$base/config.tsv"

[[ ! -e "$base/journal.tsv" ]]
unsafe="$tmp/unsafe"
mkdir -p "$unsafe"
printf 'ACTUAL_JOURNAL_FILE=../escape.journal\n' >"$unsafe/config.tsv"
if bqn src_edit/actual_journal_file_cmd.bqn "$unsafe" >"$tmp/unsafe.out" 2>&1; then
  echo 'FAIL: unsafe Journal path accepted' >&2
  exit 1
fi
grep -Fq 'ACTUAL_JOURNAL_FILE must be a safe .journal basename' "$tmp/unsafe.out"
report_out="$tmp/report.out"
tools/report "$base" >"$report_out"
[[ -s "$report_out" && ! -e "$base/journal.tsv" ]]

before_sha=$(shasum -a 256 "$base/actual.journal" | awk '{print $1}')
before_transaction_count="$(tools/edit --base "$base" journal list --format tsv | wc -l | tr -d ' ')"
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
[[ "$(tools/edit --base "$base" journal list --format tsv | wc -l | tr -d ' ')" -eq $((before_transaction_count + 1)) ]]

daily_event_count="$after_event_count"
tools/edit --base "$base" plan add --date 2026-08-20 --memo 'Journal-only plan completion' --from assets:cash --to expenses:rent --amount 40 --id plan-2026-08-20-journal-cutover --yes --post-check none
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
