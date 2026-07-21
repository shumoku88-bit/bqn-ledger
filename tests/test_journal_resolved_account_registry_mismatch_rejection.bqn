#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
carrier_module ← •Import "../src_next/journal_read_only_source_carrier.bqn"
ak ← •Import "../src_next/account_key.bqn"

cycleStart ← "2026-08-01"

# Synthetic inline Journal lines
# Both accounts are declared in the journal, transaction is balanced and valid.
journalLines ← ⟨
  "commodity JPY",
  "",
  "account assets:bank",
  "",
  "account expenses:unresolved",
  "",
  "2026-08-15 * Balanced transaction with registry mismatch",
  "  ; layer: actual",
  "  assets:bank          -500 JPY",
  "  expenses:unresolved   500 JPY"
⟩

lf ← @+10
raw ← ∾ journalLines ∾¨ lf
parsed ← parser.Parse raw

# Stage 1 assertions
"ok" lib.AssertEq parsed.state
0 lib.AssertEq ≠ parsed.diagnostics
1 lib.AssertEq ≠ parsed.transactions
transaction ← ⊑ parsed.transactions
2 lib.AssertEq ≠ transaction.postings

# Synthetic resolved accounts
# assets:bank is in resolved accounts registry, but expenses:unresolved is deliberately absent.
# TAB is @+9.
accountLines ← ⟨"assets:bank" ∾ (@+9) ∾ "role=asset"⟩
resolved ← ak.Resolve accountLines

# Direct Stage 2A assertions
adapterResult ← adapter.Build ⟨parsed.transactions, resolved, cycleStart⟩
"error" lib.AssertEq adapterResult.state
0 lib.AssertEq ≠ adapterResult.posting_rows
lib.Assert 0 < ≠ adapterResult.diagnostics

# Diagnostic checks
diagnostic ← ⊑ adapterResult.diagnostics
"error" lib.AssertEq diagnostic.severity
"journal_posting_ir_stage2a" lib.AssertEq diagnostic.stage
"posting_account_unresolved" lib.AssertEq diagnostic.code
"expenses:unresolved" lib.AssertEq diagnostic.account_key
0 lib.AssertEq diagnostic.transaction_index
1 lib.AssertEq diagnostic.posting_index
lib.Assert 0 < ≠ diagnostic.message

# Carrier assertions
carrier ← {
  source_file ⇐ "synthetic-mismatch.journal",
  lines ⇐ journalLines
}
carrierResult ← carrier_module.Build ⟨carrier, resolved, cycleStart⟩

"error" lib.AssertEq carrierResult.state
"synthetic-mismatch.journal" lib.AssertEq carrierResult.source_file

# Check transactions remains observable
1 lib.AssertEq ≠ carrierResult.transactions
tx1 ← ⊑ parsed.transactions
tx2 ← ⊑ carrierResult.transactions
tx1.source_event_id lib.AssertEq tx2.source_event_id
tx1.date lib.AssertEq tx2.date
tx1.description lib.AssertEq tx2.description

0 lib.AssertEq ≠ carrierResult.posting_rows
lib.Assert 0 < ≠ carrierResult.diagnostics

# Ensure carrierResult's diagnostics contains the stage 2a diagnostic
carrierDiagnostic ← ⊑ carrierResult.diagnostics
"error" lib.AssertEq carrierDiagnostic.severity
"journal_posting_ir_stage2a" lib.AssertEq carrierDiagnostic.stage
"posting_account_unresolved" lib.AssertEq carrierDiagnostic.code
"expenses:unresolved" lib.AssertEq carrierDiagnostic.account_key
0 lib.AssertEq carrierDiagnostic.transaction_index
1 lib.AssertEq carrierDiagnostic.posting_index

•Out "test_journal_resolved_account_registry_mismatch_rejection.bqn: OK"
