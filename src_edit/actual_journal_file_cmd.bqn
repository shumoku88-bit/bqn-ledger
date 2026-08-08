# Emit the canonical Actual Journal basename for editor routes.
canonical ← •Import "../src/application/canonical_household_sources.bqn"
args ← •args
{𝕊: •Out "ERROR: expected base" ⋄ •Exit 2}⍟(1≠≠args) @
•Out canonical.actual
