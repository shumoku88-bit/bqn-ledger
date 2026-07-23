#!/usr/bin/env bqn
# Mandatory semantic verifier for a published cleanup rewrite.

loader ← •Import "../src_next/loader.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
cleanup ← •Import "journal_cleanup_plan.bqn"
rewrite ← •Import "journal_cleanup_rewrite.bqn"

args ← •args ⋄ tab ← @+9
Fail ← {𝕊 code: •Out "ERROR"∾tab∾code ⋄ •Exit 1}
{𝕊: Fail "usage"}⍟(2≠≠args) @
before ← parser.ParseWithProfile ⟨loader.ReadRaw (0⊑args),"historical_external_plan"⟩
after ← parser.ParseWithProfile ⟨loader.ReadRaw (1⊑args),"historical_external_plan"⟩
{𝕊: Fail "before_invalid"}⍟(before.state≢"ok") @
{𝕊: Fail "after_invalid"}⍟(after.state≢"ok") @
rows ← cleanup.Build before.transactions
verified ← rewrite.VerifyEquivalent ⟨before.transactions,after.transactions,rows⟩
{𝕊: Fail (⊑verified.diagnostics).code}⍟(verified.state≢"ok") @
removed ← +´0∾{𝕩.classification≡"REMOVABLE"}¨rows
•Out "OK"∾tab∾"CLEANUP_EQUIVALENT"∾tab∾(•Fmt≠before.transactions)∾tab∾•Fmt removed
