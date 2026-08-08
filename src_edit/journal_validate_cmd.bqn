# Strict post-write validation for canonical actual.journal only.
# Plan, Budget, report context, and unrelated Household policy are out of scope.

canonical ← •Import "../src/application/canonical_household_sources.bqn"
actual ← •Import "../src/application/editor_actual.bqn"
args ← •args
tab ← @+9
{𝕊:•Out "ERROR"∾tab∾"usage"∾tab∾"expected base" ⋄ •Exit 2}⍟(1≠≠args) @
base ← ⊑args
rows ← actual.LoadTransactionRows base
•Out "OK"∾tab∾"NATIVE_JOURNAL"∾tab∾canonical.actual∾tab∾(•Fmt ≠rows)
