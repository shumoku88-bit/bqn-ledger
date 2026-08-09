#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

base="fixtures/canonical-household-v1"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }

declare -A before=()
for name in accounts.journal actual.journal plan.journal budget.journal budget.toml household.toml report.toml issues.tsv; do
  before["$name"]="$(sha_file "$base/$name")"
done

expected="$tmp/expected"
actual="$tmp/actual"

./tools/edit --base "$base" journal list --format text >"$expected"
./tools/bl --base "$base" transactions >"$actual"
grep -Fq '=== Actual Transactions ===' "$actual"
sed '1d' "$actual" >"$tmp/actual-body"
cmp "$expected" "$tmp/actual-body"

./tools/edit --base "$base" plan list --format text >"$expected"
./tools/bl --base "$base" plans >"$actual"
grep -Fq '=== Open Plans ===' "$actual"
sed '1d' "$actual" >"$tmp/actual-body"
cmp "$expected" "$tmp/actual-body"

./tools/edit --base "$base" account list >"$expected"
./tools/bl --base "$base" accounts >"$actual"
grep -Fq '=== Accounts ===' "$actual"
sed '1d' "$actual" >"$tmp/actual-body"
cmp "$expected" "$tmp/actual-body"

./tools/edit --base "$base" issue list --format text >"$expected"
./tools/bl --base "$base" issue-list >"$actual"
grep -Fq '=== Issues & Decisions ===' "$actual"
sed '1d' "$actual" >"$tmp/actual-body"
cmp "$expected" "$tmp/actual-body"

./tools/bl --base "$base" check >"$tmp/check.out"
grep -Fq 'Canonical Household source is valid.' "$tmp/check.out"

./tools/bl --base "$base" doctor >"$tmp/doctor.out"
grep -Fq 'All checks passed.' "$tmp/doctor.out"

./tools/bl --base "$base" inspect >"$tmp/inspect.out"
grep -Fq $'ledger_inspect\tstate\tok' "$tmp/inspect.out"

export_dir="$tmp/hledger"
HLEDGER_DATA_DIR="$export_dir" ./tools/bl --base "$base" export >"$tmp/export.out"
for name in accounts.journal actual.journal plan.journal hledger.journal; do
  [[ -f "$export_dir/$name" ]] || { echo "FAIL: missing hledger export $name" >&2; exit 1; }
done
cmp "$base/accounts.journal" "$export_dir/accounts.journal"
cmp "$base/actual.journal" "$export_dir/actual.journal"
cmp "$base/plan.journal" "$export_dir/plan.journal"

# The household-facing check route must not silently regress to the repository suite.
grep -Fq '"$ROOT_DIR/tools/ledger-check" "$base_dir"' tools/bl
grep -Fq 'dev-check' tools/bl
grep -Fq '"$ROOT_DIR/tools/check.sh"' tools/bl

for name in accounts.journal actual.journal plan.journal budget.journal budget.toml household.toml report.toml issues.tsv; do
  after="$(sha_file "$base/$name")"
  [[ "$after" == "${before[$name]}" ]] || {
    echo "FAIL: Command Hub read/operation routes mutated $name" >&2
    exit 1
  }
done

echo 'check-command-hub-household-routing: OK'
