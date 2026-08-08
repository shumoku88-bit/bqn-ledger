#!/usr/bin/env bash
set -euo pipefail

# Verify BQN-backed `plan related` owns recurring-plan relation semantics over
# canonical plan.journal Facts.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
base="$tmp_root/plan-related"
cp -R fixtures/canonical-household-v1 "$base"

cat >>"$base/plan.journal" <<'EOF'

2026-01-10 * Phone current
  ; plan-id: plan-2026-01-10-phone
  Assets:Bank  -1500 JPY
  Expenses:Groceries  1500 JPY

2026-02-10 * Future phone
  ; plan-id: plan-2026-02-10-phone
  Assets:Bank  -1500 JPY
  Expenses:Groceries  1500 JPY

2026-01-11 * Exact current
  ; plan-id: exact-current
  Assets:Bank  -500 JPY
  Expenses:Groceries  500 JPY

2026-02-20 * Exact future
  ; plan-id: exact-future
  Assets:Bank  -500 JPY
  Expenses:Groceries  500 JPY
EOF

out="$(./tools/edit --base "$base" plan related --id plan-2026-01-10-phone --actual-date 2026-01-12 --format tsv)"
if ! grep -q $'^KEY\tseries\tphone$' <<< "$out"; then
  echo 'FAIL: missing plan-id relation key' >&2
  printf '%s\n' "$out" >&2
  exit 1
fi
if ! grep -q $'^ROW\t2026-02-10\tFuture phone\tAssets:Bank\tExpenses:Groceries\t1500\tplan-2026-02-10-phone' <<< "$out"; then
  echo 'FAIL: missing related future Plan row' >&2
  printf '%s\n' "$out" >&2
  exit 1
fi
if grep -q $'^ROW\t2026-01-10\tPhone current' <<< "$out"; then
  echo 'FAIL: related result included a Plan on/before Actual date' >&2
  exit 1
fi

# Generic canonical plan-id values do not imply a series. They use the exact
# description/from/to/amount fallback instead of reintroducing TSV metadata rules.
exact_out="$(./tools/edit --base "$base" plan related --id exact-current --actual-date 2026-01-12 --format tsv)"
if ! grep -q $'^KEY\texact\tExact current\tAssets:Bank\tExpenses:Groceries\t500$' <<< "$exact_out"; then
  echo 'FAIL: exact canonical fallback key missing' >&2
  printf '%s\n' "$exact_out" >&2
  exit 1
fi

# Add a second Plan with the same exact relation fields so it is discoverable.
python3 - "$base/plan.journal" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
s = s.replace('2026-02-20 * Exact future', '2026-02-20 * Exact current')
p.write_text(s)
PY
exact_out="$(./tools/edit --base "$base" plan related --id exact-current --actual-date 2026-01-12 --format tsv)"
if ! grep -q $'^ROW\t2026-02-20\tExact current\tAssets:Bank\tExpenses:Groceries\t500\texact-future' <<< "$exact_out"; then
  echo 'FAIL: exact fallback related row missing' >&2
  printf '%s\n' "$exact_out" >&2
  exit 1
fi

# Legacy plan.tsv content cannot redirect relation discovery.
printf 'bogus\tlegacy\tplan\trow\t1\n' >"$base/plan.tsv"
legacy_out="$(./tools/edit --base "$base" plan related --id plan-2026-01-10-phone --actual-date 2026-01-12 --format tsv)"
if ! grep -q $'^ROW\t2026-02-10\tFuture phone' <<< "$legacy_out"; then
  echo 'FAIL: legacy plan.tsv interfered with canonical related lookup' >&2
  exit 1
fi

printf 'OK: canonical tools/edit-bqn plan related checks passed\n'
