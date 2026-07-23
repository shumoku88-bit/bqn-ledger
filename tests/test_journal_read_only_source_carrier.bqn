#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
carrier_module ← •Import "../src_next/journal_read_only_source_carrier.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

cycleStart ← "2026-08-01"
lf ← @+10
accountLines ← ⟨
  "assets:anonymous-cash"∾(@+9)∾"role=asset",
  "expenses:anonymous-first"∾(@+9)∾"role=expense",
  "expenses:anonymous-second"∾(@+9)∾"role=expense"
⟩
resolved ← ak.Resolve accountLines

# Success path test uses native Journal evidence only.
rawJournal ← ∾⟨
  "commodity JPY",lf,lf,
  "account assets:anonymous-cash",lf,lf,
  "account expenses:anonymous-first",lf,lf,
  "account expenses:anonymous-second",lf,lf,
  "2026-08-03 * split transaction",lf,
  "    expenses:anonymous-first 800 JPY",lf,
  "    expenses:anonymous-second 300 JPY",lf,
  "    assets:anonymous-cash -1100 JPY",lf
⟩
journalLines ← lf loader.SplitKeepEmpty rawJournal
carrier ← {
  source_file ⇐ "test-identity.journal",
  lines ⇐ journalLines
}

carrierResult ← carrier_module.Build ⟨carrier, resolved, cycleStart⟩

# 1. explicit source identity is retained in result, but rows' source_file is unmodified
"test-identity.journal" lib.AssertEq carrierResult.source_file
lib.Assert ∧´ {"profile.journal" ≡ 𝕩.source_file}¨ carrierResult.posting_rows

# 2. carrier/parse state is ok
"ok" lib.AssertEq carrierResult.state

# 3. transaction count is 1
1 lib.AssertEq ≠ carrierResult.transactions

# 4. ordered posting count is 3
transaction ← ⊑ carrierResult.transactions
3 lib.AssertEq ≠ transaction.postings

# 5. Posting IR row count is 3
3 lib.AssertEq ≠ carrierResult.posting_rows

# 6. All Posting IR rows are in success state
lib.Assert ∧´ {"ok" ≡ 𝕩.status}¨ carrierResult.posting_rows

# 7. delta sum is 0
0 lib.AssertEq +´ {𝕩.delta}¨ carrierResult.posting_rows

# 8. diagnostics do not hide meaning (empty here because it's successful)
0 lib.AssertEq ≠ carrierResult.diagnostics


# Negative path test (unbalanced transaction)
invalidLines ← ⟨
  "commodity JPY",
  "",
  "account expenses:anonymous-first",
  "",
  "account expenses:anonymous-second",
  "",
  "2026-08-03 * unbalanced transaction",
  "  expenses:anonymous-first   800 JPY",
  "  expenses:anonymous-second  300 JPY"
⟩
invalidCarrier ← {
  source_file ⇐ "invalid.journal",
  lines ⇐ invalidLines
}

invalidResult ← carrier_module.Build ⟨invalidCarrier, resolved, cycleStart⟩

"error" lib.AssertEq invalidResult.state
0 lib.AssertEq ≠ invalidResult.posting_rows
lib.Assert 0 < ≠ invalidResult.diagnostics

# Check that the diagnostic has expected fields and does not hide Stage 1 error meaning
diagnostic ← ⊑ invalidResult.diagnostics
"error" lib.AssertEq diagnostic.severity
"journal_profile_stage1" lib.AssertEq diagnostic.stage
"event_unbalanced" lib.AssertEq diagnostic.code

•Out "test_journal_read_only_source_carrier.bqn: OK"
