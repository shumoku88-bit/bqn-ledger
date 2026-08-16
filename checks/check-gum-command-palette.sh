#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
base="$root/fixtures/ledger-facts-phase1-proof"
work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-gum-hub.XXXXXX")"
trap 'rm -rf "$work"' EXIT

bash -n tools/household-hub-gum tools/household-action
[[ -x tools/household-hub-gum ]]
[[ -x tools/household-action ]]

# All logical Household actions are published in one BQN-owned relation so a
# flat frontend never reconstructs the Domain × Operation catalog itself.
tools/household-surface-metadata actions >"$work/actions.tsv"
head -n1 "$work/actions.tsv" | grep -Fx $'action_index\tdomain_key\toperation_key\tscope\taction_key\taction_label\taction_kind' >/dev/null
awk -F'\t' 'NR>1 && $5=="expense" && $2=="actual" && $3=="add" && $4=="selected-date" && $7=="command" {ok=1} END{exit !ok}' "$work/actions.tsv"
awk -F'\t' 'NR>1 && $5=="balance-sheet" && $2=="household" && $7=="report" {ok=1} END{exit !ok}' "$work/actions.tsv"
awk -F'\t' 'NR>1 {seen[$5]++} END {for (k in seen) if (seen[k] != 1) exit 1}' "$work/actions.tsv"

# The gum frontend is a flat command palette. Calendar and system utilities are
# siblings around the logical action relation rather than taxonomy submenus.
tools/household-hub-gum --base "$base" --date 2026-08-16 --list >"$work/palette.tsv"
grep -Fq $'meta:calendar\tCalendar' "$work/palette.tsv"
grep -Fq $'meta:reports\tBrowse Reports' "$work/palette.tsv"
grep -Fq $'action:expense\tExpense' "$work/palette.tsv"
grep -Fq $'action:balance-sheet\tBalance Sheet' "$work/palette.tsv"
grep -Fq $'meta:check\tHousehold check' "$work/palette.tsv"
awk -F'\t' '{seen[$1]++} END {for (k in seen) if (seen[k] != 1) exit 1}' "$work/palette.tsv"

# Physical frontend and dispatcher do not acquire canonical source ownership.
if rg -n 'actual\.journal|plan\.journal|budget\.journal|accounts\.journal|household\.toml' \
  tools/household-hub-gum tools/household-action >/dev/null; then
  echo 'FAIL: gum frontend/dispatcher acquired canonical source vocabulary' >&2
  exit 1
fi

# Invalid UI Date context and unknown logical actions fail before dispatch.
if tools/household-action --base "$base" --date nope expense >"$work/invalid.out" 2>"$work/invalid.err"; then
  echo 'FAIL: household-action accepted an invalid date' >&2
  exit 1
fi
grep -Fq -- '--date must be YYYY-MM-DD' "$work/invalid.err"
if tools/household-action --base "$base" --date 2026-08-16 check >"$work/unknown.out" 2>"$work/unknown.err"; then
  echo 'FAIL: household-action accepted an action outside HouseholdSurface.Actions' >&2
  exit 1
fi
grep -Fq 'unknown Household action: check' "$work/unknown.err"

for key in journal-list expense plan-finish budget-move account-add issue-close; do
  grep -Fq "$key" tools/household-action || {
    echo "FAIL: shared Household dispatcher is missing $key" >&2
    exit 1
  }
done

echo 'check-gum-command-palette: OK'
