#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/wrapper_success.bqn" <<BQN
ctx ← •Import "$ROOT_DIR/src_next/context.bqn"
ak ← •Import "$ROOT_DIR/src_next/account_key.bqn"
tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}
Snapshot ← {𝕊 lines:
  {sources⇐⟨
    {source_file⇐"actual.journal",required⇐1,lines⇐lines},
    {source_file⇐"plan.tsv",required⇐0,lines⇐⟨⟩},
    {source_file⇐"budget_alloc.tsv",required⇐0,lines⇐⟨⟩}
  ⟩}
}
resolved ← ak.Resolve ⟨"assets:bank"∾tab∾"role=asset", "expenses:food"∾tab∾"role=expense"⟩
jSnapshot ← Snapshot ⟨Line ⟨"2026-06-15", "ok", "assets:bank", "expenses:food", "100"⟩⟩
built ← ctx.BuildAuthorizedRowsFromSnapshot ⟨jSnapshot, resolved, "2026-06-15"⟩
{𝕊: •Out "unexpected-success-shape" ⋄ •Exit 2}⍟((≠built.rows)≠2) @
{𝕊: •Out "unexpected-success-proof" ⋄ •Exit 2}⍟(built.arithmetic_currency_proof.state≢"proven") @
•Out "wrapper-success-ok"
BQN

success_out="$(bqn "$tmp/wrapper_success.bqn" 2>&1)"
if [ "$success_out" != "wrapper-success-ok" ]; then
  echo "FAIL: compatibility wrapper emitted extra success output or changed shape" >&2
  echo "$success_out" >&2
  exit 1
fi

cat > "$tmp/wrapper_proof_rejection.bqn" <<BQN
ctx ← •Import "$ROOT_DIR/src_next/context.bqn"
ak ← •Import "$ROOT_DIR/src_next/account_key.bqn"
tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}
Snapshot ← {𝕊 lines:
  {sources⇐⟨
    {source_file⇐"actual.journal",required⇐1,lines⇐lines},
    {source_file⇐"plan.tsv",required⇐0,lines⇐⟨⟩},
    {source_file⇐"budget_alloc.tsv",required⇐0,lines⇐⟨⟩}
  ⟩}
}
resolved ← ak.Resolve ⟨"assets:bank"∾tab∾"role=asset", "expenses:food"∾tab∾"role=expense"⟩
eurSnapshot ← Snapshot ⟨Line ⟨"2026-06-15", "eur", "assets:bank", "expenses:food", "100", "currency=EUR"⟩⟩
ctx.BuildAuthorizedRowsFromSnapshot ⟨eurSnapshot, resolved, "2026-06-15"⟩
•Out "unexpected-proof-ok"
BQN

set +e
proof_out="$(bqn "$tmp/wrapper_proof_rejection.bqn" 2>"$tmp/proof.err")"
proof_status=$?
set -e
expected_proof='ERROR: explicit source currency unsupported in Stage 2 minimal runtime slice: actual.journal row 0: unsupported currency: EUR'
if [ "$proof_status" -ne 1 ]; then
  echo "FAIL: proof rejection exit code changed: $proof_status" >&2
  cat "$tmp/proof.err" >&2
  exit 1
fi
if [ "$proof_out" != "$expected_proof" ]; then
  echo "FAIL: proof rejection stdout changed" >&2
  printf 'expected: %s\nactual:   %s\n' "$expected_proof" "$proof_out" >&2
  cat "$tmp/proof.err" >&2
  exit 1
fi

cat > "$tmp/wrapper_structure_rejection.bqn" <<BQN
ctx ← •Import "$ROOT_DIR/src_next/context.bqn"
ak ← •Import "$ROOT_DIR/src_next/account_key.bqn"
tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}
Snapshot ← {𝕊 lines:
  {sources⇐⟨
    {source_file⇐"actual.journal",required⇐1,lines⇐lines},
    {source_file⇐"plan.tsv",required⇐0,lines⇐⟨⟩},
    {source_file⇐"budget_alloc.tsv",required⇐0,lines⇐⟨⟩}
  ⟩}
}
resolved ← ak.Resolve ⟨"assets:bank"∾tab∾"role=asset", "expenses:food"∾tab∾"role=expense"⟩
goodSnapshot ← Snapshot ⟨Line ⟨"2026-06-15", "ok", "assets:bank", "expenses:food", "100"⟩⟩
good ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨goodSnapshot, resolved, "2026-06-15"⟩
arithmetic ← good.arithmetic_evidence
mismatched ← {
  state⇐arithmetic.state,
  domain⇐arithmetic.domain,
  amount_scale⇐arithmetic.amount_scale,
  normalized_coefficients⇐⟨⟩,
  message⇐arithmetic.message
}
ctx.BuildAuthorizedRowsFromPreparedForTest ⟨good.row_evidence, mismatched, resolved, "2026-06-15"⟩
•Out "unexpected-structure-ok"
BQN

set +e
structure_out="$(bqn "$tmp/wrapper_structure_rejection.bqn" 2>"$tmp/structure.err")"
structure_status=$?
set -e
expected_structure='ERROR: evidence and normalized coefficients length mismatch'
if [ "$structure_status" -ne 1 ]; then
  echo "FAIL: structure rejection exit code changed: $structure_status" >&2
  cat "$tmp/structure.err" >&2
  exit 1
fi
if [ "$structure_out" != "$expected_structure" ]; then
  echo "FAIL: structure rejection stdout changed" >&2
  printf 'expected: %s\nactual:   %s\n' "$expected_structure" "$structure_out" >&2
  cat "$tmp/structure.err" >&2
  exit 1
fi

printf 'OK: checked posting projection result and wrapper parity passed\n'
