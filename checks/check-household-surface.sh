#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-household-surface.XXXXXX")"
trap 'rm -rf "$work"' EXIT

./tools/household-surface-metadata >"$work/surface.tsv"
[[ "$(wc -l <"$work/surface.tsv" | tr -d ' ')" == 25 ]]
head -n1 "$work/surface.tsv" | grep -Fx $'domain_index\tdomain_key\tdomain_label\toperation_index\toperation_key\toperation_label\tenabled\tcell_label' >/dev/null

# The visible surface is one rectangular Domain × Operation relation.
[[ "$(awk -F'\t' 'NR>1{seen[$2]=1} END{print length(seen)}' "$work/surface.tsv")" == 6 ]]
[[ "$(awk -F'\t' 'NR>1{seen[$5]=1} END{print length(seen)}' "$work/surface.tsv")" == 4 ]]
[[ "$(awk -F'\t' 'NR>1 && $7==1{n++} END{print n+0}' "$work/surface.tsv")" == 15 ]]

require_cell() {
  local domain="$1" operation="$2" enabled="$3" label="$4"
  awk -F'\t' -v d="$domain" -v o="$operation" -v e="$enabled" -v l="$label" \
    'NR>1 && $2==d && $5==o && $7==e && $8==l{found=1} END{exit !found}' "$work/surface.tsv"
}
require_cell actual observe 1 Journal
require_cell actual change 0 ''
require_cell actual resolve 1 Reverse
require_cell plan change 1 Edit
require_cell plan resolve 1 Finish
require_cell envelope add 1 Move
require_cell issue resolve 1 Close
require_cell household observe 1 Reports
require_cell household add 0 ''

./tools/report-section-metadata >"$work/reports.tsv"
# Report placement is owned by the existing report catalog, not duplicated in
# the Household surface relation.
awk -F'\t' 'NR>1 && $5=="actual" && $6=="recent" && $1=="recent"{a=1}
             NR>1 && $5=="plan" && $6=="future" && $1=="planned"{p=1}
             NR>1 && $5=="envelope" && $1=="envelopes"{e=1}
             NR>1 && $5=="account" && $6=="month" && $1=="monthly-accounts"{m=1}
             NR>1 && $5=="issue" && $1=="issues"{i=1}
             NR>1 && $5=="household" && $1=="balance-sheet"{h=1}
             END{exit !(a&&p&&e&&m&&i&&h)}' "$work/reports.tsv"

if rg -n 'fzf|gum|ANSI|escape sequence|mouse' src/application/household_surface.bqn >/dev/null; then
  echo 'FAIL: physical frontend vocabulary leaked into Household surface semantics' >&2
  exit 1
fi
if rg -n 'actual\.journal|plan\.journal|budget\.journal|issues\.tsv|•FChars|source_io' src/application/household_surface.bqn >/dev/null; then
  echo 'FAIL: Household surface semantics gained canonical source ownership' >&2
  exit 1
fi

echo 'check-household-surface: OK'
