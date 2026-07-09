#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

make_fixture() {
  local dir="$1" journal_line="$2" plan_line="${3:-}" budget_line="${4:-}"
  mkdir -p "$dir"
  printf 'assets:bank\trole=asset\nexpenses:food\trole=expense\nbudget:food\trole=budget\n' > "$dir/accounts.tsv"
  printf 'mode\tfixed\nstart\t2026-06-15\nend_exclusive\t2026-06-22\n' > "$dir/cycle.tsv"
  printf '%s\n' "$journal_line" > "$dir/journal.tsv"
  [ -z "$plan_line" ] || printf '%s\n' "$plan_line" > "$dir/plan.tsv"
  [ -z "$budget_line" ] || printf '%s\n' "$budget_line" > "$dir/budget_alloc.tsv"
}

expect_fail_context() {
  local dir="$1" label="$2" out status
  set +e
  out="$(bqn -e 'ctx←•Import "src_next/context.bqn" ⋄ ctx.BuildContext "'"$dir"'" ⋄ •Out "unexpected-ok"' 2>&1)"
  status=$?
  set -e
  if [ "$status" -eq 0 ]; then
    echo "FAIL: explicit currency fixture unexpectedly succeeded: $label" >&2
    echo "$out" >&2
    exit 1
  fi
  case "$out" in
    *"explicit source currency unsupported"*) ;;
    *) echo "FAIL: missing explicit currency diagnostic for $label" >&2; echo "$out" >&2; exit 1 ;;
  esac
}

clean='2026-06-15	memo	assets:bank	expenses:food	100'
make_fixture "$tmp/journal-currency" "2026-06-15	memo	assets:bank	expenses:food	100	currency=JPY"
make_fixture "$tmp/plan-currency" "$clean" "2026-06-16	plan	assets:bank	expenses:food	20	currency=USD"
make_fixture "$tmp/budget-currency" "$clean" "" "2026-06-16	budget	assets:bank	budget:food	20	currency="
expect_fail_context "$tmp/journal-currency" journal
expect_fail_context "$tmp/plan-currency" plan
expect_fail_context "$tmp/budget-currency" budget_alloc

same_dir="$tmp/same-snapshot"
make_fixture "$same_dir" "$clean"
cat > "$tmp/same_snapshot.bqn" <<BQN
ctx ← •Import "$ROOT_DIR/src_next/context.bqn"
ak ← •Import "$ROOT_DIR/src_next/account_key.bqn"
loader ← •Import "$ROOT_DIR/src_next/loader.bqn"
base ← 0⊑•args
snapshot ← ctx.LoadPostingSourceSnapshot base
proof ← ctx.ResolveArithmeticCurrencyProof snapshot
(base∾"/journal.tsv") •file.Chars "2026-06-15\tmutated\tassets:bank\texpenses:food\t999\n"
resolved ← ak.Resolve loader.ReadLines (base∾"/accounts.tsv")
built ← ctx.BuildAuthorizedRowsFromSnapshot ⟨snapshot, resolved, "2026-06-15"⟩
rows ← built.rows
debits ← (({𝕩.side}¨ rows) ≡¨ <"debit") / rows
amount ← (⊑ debits).delta
{𝕊: •Out "FAIL: same snapshot amount was "∾•Fmt amount ⋄ •Exit 1}⍟(amount≠100) @
•Out "same-snapshot-ok"
BQN
set +e
same_out="$(bqn "$tmp/same_snapshot.bqn" "$same_dir" 2>&1)"
same_status=$?
set -e
if [ "$same_status" -ne 0 ]; then
  echo "FAIL: same snapshot check failed" >&2
  echo "$same_out" >&2
  exit 1
fi
case "$same_out" in
  *"same-snapshot-ok"*) ;;
  *) echo "FAIL: same snapshot check failed" >&2; echo "$same_out" >&2; exit 1 ;;
esac

cat > "$tmp/inconsistent_snapshot.bqn" <<BQN
ctx ← •Import "$ROOT_DIR/src_next/context.bqn"
ak ← •Import "$ROOT_DIR/src_next/account_key.bqn"
loader ← •Import "$ROOT_DIR/src_next/loader.bqn"
base ← "$same_dir"
resolved ← ak.Resolve loader.ReadLines (base∾"/accounts.tsv")
tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}
clean ← Line ⟨"2026-06-15", "clean", "assets:bank", "expenses:food", "100"⟩
dirty ← Line ⟨"2026-06-15", "dirty", "assets:bank", "expenses:food", "999", "currency=USD"⟩
snapshot ← {
  journal ⇐ {source_file⇐"journal.tsv", required⇐1, lines⇐⟨dirty⟩},
  sources ⇐ ⟨
    {source_file⇐"journal.tsv", required⇐1, lines⇐⟨clean⟩},
    {source_file⇐"plan.tsv", required⇐0, lines⇐⟨⟩},
    {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
  ⟩
}
built ← ctx.BuildAuthorizedRowsFromSnapshot ⟨snapshot, resolved, "2026-06-15"⟩
debits ← (({𝕩.side}¨ built.rows) ≡¨ <"debit") / built.rows
amount ← (⊑ debits).delta
{𝕊: •Out "FAIL: inconsistent snapshot projected non-canonical amount "∾•Fmt amount ⋄ •Exit 1}⍟(amount≠100) @
•Out "inconsistent-snapshot-canonical-ok"
BQN
inconsistent_out="$(bqn "$tmp/inconsistent_snapshot.bqn" 2>&1)"
case "$inconsistent_out" in
  *"inconsistent-snapshot-canonical-ok"*) ;;
  *) echo "FAIL: inconsistent snapshot canonical-source check failed" >&2; echo "$inconsistent_out" >&2; exit 1 ;;
esac

cat > "$tmp/cross_snapshot_substitution.bqn" <<BQN
ctx ← •Import "$ROOT_DIR/src_next/context.bqn"
ak ← •Import "$ROOT_DIR/src_next/account_key.bqn"
loader ← •Import "$ROOT_DIR/src_next/loader.bqn"
baseA ← "$same_dir"
baseB ← "$tmp/journal-currency"
snapshotA ← ctx.LoadPostingSourceSnapshot baseA
proofA ← ctx.ResolveArithmeticCurrencyProof snapshotA
snapshotB ← ctx.LoadPostingSourceSnapshot baseB
resolved ← ak.Resolve loader.ReadLines (baseA∾"/accounts.tsv")
# Old vulnerable shape with independent proof must not be accepted.
ctx.BuildAllRowsFromSnapshot ⟨snapshotB, resolved, "2026-06-15", proofA⟩
•Out "unexpected-old-api-ok"
BQN
set +e
cross_out="$(bqn "$tmp/cross_snapshot_substitution.bqn" 2>&1)"
cross_status=$?
set -e
if [ "$cross_status" -eq 0 ]; then
  echo "FAIL: cross-snapshot substitution old API unexpectedly succeeded" >&2
  echo "$cross_out" >&2
  exit 1
fi

set +e
forged_out="$(bqn -e 'proj←•Import "src_next/projection.bqn" ⋄ proof←{state⇐"proven",domain⇐"JPY",basis⇐"legacy_compatibility",message⇐""} ⋄ proj.MakeRowsAuthorized ⟨proof,⟨⟩⟩ ⋄ •Out "unexpected-ok"' 2>&1)"
forged_status=$?
set -e
if [ "$forged_status" -eq 0 ]; then
  echo "FAIL: exported projection accepted a forged plain proof" >&2
  echo "$forged_out" >&2
  exit 1
fi

set +e
alias_out="$(bqn -e 'ctx←•Import "src_next/context.bqn" ⋄ loader←•Import "src_next/loader.bqn" ⋄ ak←•Import "src_next/account_key.bqn" ⋄ base←"fixtures/src-next-golden" ⋄ resolved←ak.Resolve loader.ReadLines (base∾"/accounts.tsv") ⋄ ctx.BuildRowsForFile ⟨base,resolved,"2026-06-15","unknown.tsv"⟩ ⋄ •Out "unexpected-ok"' 2>&1)"
alias_status=$?
set -e
if [ "$alias_status" -eq 0 ]; then
  echo "FAIL: unknown posting source silently mapped to a known source" >&2
  echo "$alias_out" >&2
  exit 1
fi
case "$alias_out" in
  *"unsupported posting source file"*) ;;
  *) echo "FAIL: missing unsupported source diagnostic" >&2; echo "$alias_out" >&2; exit 1 ;;
esac

if rg 'proj\.MakeRow|proj\.MakeRowsAuthorized|MakeRow ¨ args' src_next tests -n >/tmp/stage2-domain-proof-rg.txt; then
  echo "FAIL: direct exported projection bypass remains" >&2
  cat /tmp/stage2-domain-proof-rg.txt >&2
  exit 1
fi

printf 'OK: src_next currency domain proof runtime checks passed\n'
