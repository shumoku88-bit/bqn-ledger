#!/usr/bin/env bash
set -euo pipefail

# Verify BQN-backed `plan related` owns recurring-plan relation semantics.

if [ -f "src_next/report.bqn" ]; then
  ROOT_DIR="$PWD"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
cd "$ROOT_DIR"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
base="$tmp_root/plan-related"
cp -R fixtures/plan-completion "$base"

# Same plan_id-derived series as the selected phone plan, with an explicit
# series meta to verify the preferred relation path remains BQN-owned.
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  '2026-02-10' 'Future phone' 'assets:bank' 'expenses:misc' '1500' \
  'plan_id=plan-2026-02-10-phone' 'series=phone' >> "$base/plan.tsv"

out="$(./tools/edit --base "$base" plan related --index 1 --actual-date 2026-01-12 --format tsv)"

if ! grep -q $'^KEY\tseries\tphone$' <<< "$out"; then
  echo "FAIL: missing relation key" >&2
  printf '%s\n' "$out" >&2
  exit 1
fi

if ! grep -q $'^ROW\t2026-02-10\tFuture phone\tassets:bank\texpenses:misc\t1500\tplan-2026-02-10-phone' <<< "$out"; then
  echo "FAIL: missing related future row" >&2
  printf '%s\n' "$out" >&2
  exit 1
fi

# Exact fallback: missing plan_id/series still groups only by exact
# memo/from/to/amount and only for future open plans.
printf '%s\t%s\t%s\t%s\t%s\n' \
  '2026-02-20' 'Unplanned food' 'assets:bank' 'expenses:food' '500' >> "$base/plan.tsv"

fallback_out="$(./tools/edit --base "$base" plan related --id plan-2026-01-24-book --actual-date 2026-01-12 --format tsv)"
if ! grep -q $'^KEY\tseries\tbook$' <<< "$fallback_out"; then
  echo "FAIL: plan_id series fallback missing" >&2
  printf '%s\n' "$fallback_out" >&2
  exit 1
fi

exact_out="$(./tools/edit --base "$base" plan related --index 3 --actual-date 2026-01-26 --format tsv)"
if ! grep -q $'^KEY\texact\tUnplanned food\tassets:bank\texpenses:food\t500$' <<< "$exact_out"; then
  echo "FAIL: exact fallback key missing" >&2
  printf '%s\n' "$exact_out" >&2
  exit 1
fi
if ! grep -q $'^ROW\t2026-02-20\tUnplanned food\tassets:bank\texpenses:food\t500\t(missing)' <<< "$exact_out"; then
  echo "FAIL: exact fallback related row missing" >&2
  printf '%s\n' "$exact_out" >&2
  exit 1
fi

printf 'OK: tools/edit-bqn plan related checks passed\n'
