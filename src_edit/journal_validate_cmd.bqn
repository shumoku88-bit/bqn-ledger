# Validate the complete configured Journal-only ledger context.
# This resolves ACTUAL_JOURNAL_FILE, parses the native Journal with the required
# profile, checks declarations/accounts, builds Posting IR, and admits plan/budget.
context ← •Import "../src_next/context.bqn"
args ← •args
tab ← @+9
{𝕊: •Out "ERROR"∾tab∾"usage"∾tab∾"expected base" ⋄ •Exit 2}⍟(1≠≠args) @
ctx ← context.BuildContext ⊑args
•Out "OK"∾tab∾"NATIVE_JOURNAL_CONTEXT"∾tab∾ctx.actual_source_file∾tab∾(•Fmt ≠ctx.actual_transactions)
