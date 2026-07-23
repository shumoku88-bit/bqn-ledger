#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

make_fixture() {
  local dir="$1" plan_line="${2:-}" budget_line="${3:-}"
  mkdir -p "$dir"
  printf 'assets:bank\trole=asset\nexpenses:food\trole=expense\nbudget:food\trole=budget\n' >"$dir/accounts.tsv"
  printf 'mode\tfixed\nstart\t2026-06-15\nend_exclusive\t2026-06-22\n' >"$dir/cycle.tsv"
  cat >"$dir/actual.journal" <<'JOURNAL'
commodity JPY

account assets:bank

account budget:food

account expenses:food
JOURNAL
  [[ -z "$plan_line" ]] || printf '%s\n' "$plan_line" >"$dir/plan.tsv"
  [[ -z "$budget_line" ]] || printf '%s\n' "$budget_line" >"$dir/budget_alloc.tsv"
}

expect_fail_context() {
  local dir="$1" label="$2" pat="$3" out status
  set +e
  out="$(bqn -e 'ctx←•Import "src_next/context.bqn" ⋄ ctx.BuildContext "'"$dir"'" ⋄ •Out "unexpected-ok"' 2>&1)"; status=$?
  set -e
  [[ "$status" -ne 0 ]] || { echo "FAIL: invalid non-actual currency unexpectedly succeeded: $label" >&2; exit 1; }
  [[ "$out" == *"$pat"* ]] || { echo "FAIL: missing diagnostic for $label" >&2; echo "$out" >&2; exit 1; }
}

clean="$tmp/clean"
plan_bad="$tmp/plan-bad"
budget_bad="$tmp/budget-bad"
make_fixture "$clean" $'2026-06-16\tplan\tassets:bank\texpenses:food\t20\tcurrency=JPY'
make_fixture "$plan_bad" $'2026-06-16\tplan\tassets:bank\texpenses:food\t20\tcurrency=EUR'
make_fixture "$budget_bad" '' $'2026-06-16\tbudget\tassets:bank\tbudget:food\t20\tcurrency='
bqn src_edit/journal_validate_cmd.bqn "$clean" >/dev/null
expect_fail_context "$plan_bad" plan 'unsupported currency: EUR'
expect_fail_context "$budget_bad" budget 'unsupported currency: '

cat >"$tmp/same_snapshot.bqn" <<BQN
ctx ← •Import "$ROOT_DIR/src_next/context.bqn"
ak ← •Import "$ROOT_DIR/src_next/account_key.bqn"
loader ← •Import "$ROOT_DIR/src_next/loader.bqn"
base ← 0⊑•args
snapshot ← ctx.LoadNonActualPostingSourceSnapshot base
(base∾"/plan.tsv") •file.Chars "2026-06-16\tmutated\tassets:bank\texpenses:food\t999\tcurrency=JPY\n"
resolved ← ak.Resolve loader.ReadLines (base∾"/accounts.tsv")
built ← ctx.BuildAuthorizedRowsFromSnapshot ⟨snapshot,resolved,"2026-06-15"⟩
debits ← (({𝕩.side}¨built.rows)≡¨<"debit")/built.rows
{𝕊: •Out "FAIL" ⋄ •Exit 1}⍟((⊑debits).delta≠20) @
•Out "same-snapshot-ok"
BQN
bqn "$tmp/same_snapshot.bqn" "$clean" | grep -Fq same-snapshot-ok

set +e
cross_out="$(bqn -e 'ctx←•Import "src_next/context.bqn" ⋄ s←ctx.LoadNonActualPostingSourceSnapshot "fixtures/src-next-golden" ⋄ ctx.BuildAllRowsFromSnapshot ⟨s,@,"2026-06-15",@⟩' 2>&1)"; cross_status=$?
set -e
[[ "$cross_status" -ne 0 ]] || { echo 'FAIL: removed independent-proof API unexpectedly succeeded' >&2; exit 1; }

set +e
alias_out="$(bqn -e 'ctx←•Import "src_next/context.bqn" ⋄ loader←•Import "src_next/loader.bqn" ⋄ ak←•Import "src_next/account_key.bqn" ⋄ base←"fixtures/src-next-golden" ⋄ resolved←ak.Resolve loader.ReadLines (base∾"/accounts.tsv") ⋄ ctx.BuildRowsForFile ⟨base,resolved,"2026-06-15","unknown.tsv"⟩' 2>&1)"; alias_status=$?
set -e
[[ "$alias_status" -ne 0 && "$alias_out" == *'unsupported posting source file'* ]] || { echo 'FAIL: unknown non-actual source was not rejected' >&2; exit 1; }

ctx_src=src_next/context.bqn
grep -q '(≠evidence) ≢ (≠arithmeticEvidence.normalized_coefficients)' "$ctx_src"
grep -q '↕ ≠ evidence' "$ctx_src"
! grep -qE '(≠⌊|⌊≠|↑¨|⌊´)' "$ctx_src"
printf 'OK: non-actual TSV currency domain proof runtime checks passed\n'
