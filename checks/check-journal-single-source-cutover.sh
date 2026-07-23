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

before=$(shasum -a 256 "$base/actual.journal" | awk '{print $1}')
tools/edit --base "$base" journal add --date 2026-08-05 --memo 'Journal-only daily add' --from assets:cash --to expenses:food --amount 25 --yes
[[ "$before" != "$(shasum -a 256 "$base/actual.journal" | awk '{print $1}')" && ! -e "$base/journal.tsv" ]]
[[ "$(tools/edit --base "$base" journal list --format tsv | wc -l | tr -d ' ')" -eq 3 ]]

tools/edit --base "$base" plan add --date 2026-08-20 --memo 'Journal-only plan completion' --from assets:cash --to expenses:household --amount 40 --id plan-2026-08-20-journal-cutover --yes
tools/edit --base "$base" plan finish --id plan-2026-08-20-journal-cutover --actual-date 2026-07-23 --apply --yes
[[ ! -e "$base/journal.tsv" ]]
tools/edit --base "$base" plan list --all --format tsv | grep -Fq $'plan-2026-08-20-journal-cutover\t2026-08-20'

tools/report "$base" >"$report_out"
[[ -s "$report_out" && ! -e "$base/journal.tsv" ]]
echo 'OK: Journal-only report, daily add, list, and plan completion passed without journal.tsv'
