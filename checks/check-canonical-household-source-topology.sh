#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

owner=src/application/canonical_household_sources.bqn
fixture=fixtures/canonical-household-v1

canonical=(
  accounts.journal
  actual.journal
  plan.journal
  budget.journal
  budget.toml
  household.toml
  report.toml
  issues.tsv
)
legacy=(
  accounts.tsv
  plan.tsv
  budget_alloc.tsv
  cycle.tsv
  daily_target_scope.tsv
  config.tsv
  report_manifests.tsv
  report_all_human.tsv
  report_all_compact.tsv
)

[[ -f $owner ]]
[[ -d $fixture ]]

for name in "${canonical[@]}"; do
  [[ -f "$fixture/$name" ]] || {
    echo "FAIL: canonical fixture missing $name" >&2
    exit 1
  }
  grep -F "\"$name\"" "$owner" >/dev/null || {
    echo "FAIL: canonical source owner does not name $name" >&2
    exit 1
  }
done

actual=$(find "$fixture" -maxdepth 1 -type f -exec basename {} \; | LC_ALL=C sort)
expected=$(printf '%s\n' "${canonical[@]}" | LC_ALL=C sort)
[[ $actual == "$expected" ]] || {
  echo 'FAIL: canonical fixture must contain exactly the eight canonical source files' >&2
  diff -u <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") >&2 || true
  exit 1
}

for name in "${legacy[@]}"; do
  [[ ! -e "$fixture/$name" ]] || {
    echo "FAIL: legacy source leaked into canonical fixture: $name" >&2
    exit 1
  }
done

echo 'check-canonical-household-source-topology: OK'
