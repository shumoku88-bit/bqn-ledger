#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-metadata.XXXXXX")
trap 'rm -rf "$work"' EXIT

./tools/report-destination-metadata >"$work/metadata.tsv"
cmp "$work/metadata.tsv" "$fixture/report_metadata.destination.tsv"
./tools/report-destination-metadata --format json >"$work/metadata.json"
cmp "$work/metadata.json" "$fixture/report_metadata.destination.json"
python3 - "$work/metadata.json" <<'PY'
import json, sys
rows = json.load(open(sys.argv[1], encoding="utf-8"))
assert len(rows) == 9
assert all(list(row) == ["key", "label", "category", "owner", "human_output", "structured_output"] for row in rows)
PY
awk -F'\t' 'NR>1{print $1}' "$work/metadata.tsv" >"$work/keys"
bqn src/application/report_selection_cli.bqn all human >"$work/catalog-keys"
cmp "$work/keys" "$work/catalog-keys"
while IFS=$'\t' read -r key label category owner human structured; do
  [[ $key == key ]] && continue
  [[ -n $label && $category =~ ^(accounting|household|operations)$ ]]
  [[ -f $owner && $human == yes && $structured == metadata ]]
done <"$work/metadata.tsv"
if grep -Eq $'^(snapshot|ytd|cycle|trial-balance|check|outlook|daily-trend|daily-flow|actual-comparison|debug)\t' "$work/metadata.tsv"; then
  echo 'FAIL: retired key leaked into destination metadata' >&2; exit 1
fi
(
  cd "$work"
  "$root/tools/report-destination-metadata" >from-empty-cwd.tsv
)
cmp "$work/from-empty-cwd.tsv" "$work/metadata.tsv"
if ./tools/report-destination-metadata --format yaml >"$work/invalid.out" 2>&1; then
  echo 'FAIL: unsupported metadata format succeeded' >&2; exit 1
fi
grep -F 'unsupported format' "$work/invalid.out" >/dev/null
if rg -n '•FChars|•file|source_io|src_next|BuildContext' src/report/catalog.bqn src/report/section_metadata.bqn src/application/report_metadata_cli.bqn >/dev/null; then
  echo 'FAIL: destination metadata gained source/runtime dependency' >&2; exit 1
fi

echo 'check-report-destination-metadata: OK'
