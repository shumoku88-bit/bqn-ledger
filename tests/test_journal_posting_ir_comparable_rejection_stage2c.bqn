#!/usr/bin/env bqn
# Native Journal rejection boundary: malformed dates, amounts, and undeclared
# posting accounts are rejected before any Posting IR rows are admitted.
lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"
base ← "fixtures/journal-posting-ir-stage2c"
resolved ← ak.Resolve loader.ReadLines (base∾"/accounts.tsv")
CheckRejected ← {𝕊 stem:
  raw ← •FChars ("../"∾base∾"/"∾stem∾".journal")
  parsed ← parser.Parse raw
  "error" lib.AssertEq parsed.state
  lib.Assert 0<≠parsed.diagnostics
  0 lib.AssertEq ≠parsed.transactions
}
CheckRejected¨⟨"invalid-date","invalid-exact-integer-amount","unknown-account"⟩
•Out "test_journal_posting_ir_comparable_rejection_stage2c.bqn: OK"
