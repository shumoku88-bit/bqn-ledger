# Strict post-write validation for the configured native Journal only.
# Plan, Budget, report context, and unrelated household policy are out of scope.

actualConfig ← •Import "../src/application/actual_journal_config.bqn"
actual ← •Import "../src/application/editor_actual.bqn"
args ← •args
tab ← @+9
{𝕊:•Out "ERROR"∾tab∾"usage"∾tab∾"expected base" ⋄ •Exit 2}⍟(1≠≠args) @
base ← ⊑args
route ← actualConfig.Resolve base
rows ← actual.LoadTransactionRows base
•Out "OK"∾tab∾"NATIVE_JOURNAL"∾tab∾route.file∾tab∾(•Fmt ≠rows)
